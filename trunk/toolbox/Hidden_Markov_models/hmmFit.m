function [model, loglikHist] = hmmFit(data, nstates, type, varargin)
%% Fit an HMM model via EM
%
%% Inputs
% data         - a cell array of observations; each observation is
%                d-by-seqLength, (where d is always 1 if type = 'discrete')
%
% nstates      - the number of hidden states
%
% type         - as string, either 'gauss', or 'discrete' depending on the
%                desired emission distribution.
%% Optional named arguments
%
% pi0           - specify an initial value for the starting distribution
%                 instead of randomly initiializing.
%
% trans0        - specify an initial value for the transition matrix
%                 instead of randomly initializing, (rows must sum to one).
%
% emission0     - specify an initial value for the emission distribution
%                 instead of randomly initializing. If type is 'discrete',
%                 this is an nstates-by-nObsStates matrix, whos rows sum to
%                 one. If type is 'gauss', this is a cell array of gauss
%                 model structs, each with fields, 'mu', 'Sigma'.
%
% piPrior       - pseudo counts for the starting distribution
%
% transPrior    - pseudo counts for the transition matrix, (either
%                nstates-by-nstates or 1-by-nstates in which case it is
%                automatically replicated.
%
% emissionPrior - If type is 'discrete', these are pseduoCounts in an
%                 nstates-by-nObsStates matrix. If type is 'gauss',
%                 emissionPrior is a struct with the parameters of a
%                 Gauss-inverseWishart distribution, namely,
%                 mu, Sigma, dof, k.
%
%% EM related inputs
% *** See emAlgo for additional EM related optional inputs ***
%
%% Outputs
%
% model         - a struct with fields, pi, A, emission, nstates, type
% loglikHist    - history of the log likelihood
%
%%
if ~iscell(data)
    if isvector(data) % scalar time series
        data = rowvec(data);
    end
    data = {data};
end
model.nstates = nstates;
model.type = type;
[   model.pi                    , ...
    model.A                     , ...
    model.emission              , ...
    model.piPrior               , ...
    model.transPrior            , ...
    model.emissionPrior         , ...
    EMargs                      ] ...
    = process_options(varargin  , ...
    'pi0'                       , []                        , ...
    'trans0'                    , []                        , ...
    'emission0'                 , []                        , ...
    'piPrior'                   , 2*ones(1, nstates)        , ...
    'transPrior'                , 2*ones(nstates, nstates)  , ...
    'emissionPrior'             , []);
model.piPrior = rowvec(model.piPrior);
if diff(size(model.transPrior))
    model.transPrior = repmat(rowvec(model.transPrior), nstates, 1);
end
%%
switch lower(type)
    case 'gauss'
        estepFn = @(model, data)estep(model, data, @estepGaussEmission);
        [model, loglikHist] = emAlgo(model, data, @initGauss, estepFn, ...
            @mstepGauss, EMargs{:});
    case 'discrete'
        estepFn = @(model, data)estep(model, data, @estepDiscreteEmission);
        [model, loglikHist] = emAlgo(model, data, @initDiscrete, estepFn,...
            @mstepDiscrete, EMargs{:});
    otherwise
        error('%s is not a valid output distribution type');
end
end

%% INIT
function model = initGauss(model, data, restartNum)
%% Initialize Gaussian model

d = size(data{1}, 1);
if isempty(model.emissionPrior)
    model.emissionPrior.mu    = zeros(1, d);
    model.emissionPrior.Sigma = 0.1*eye(d);
    model.emissionPrior.k     = d;
    model.emissionPrior.dof   = d + 1;
end
model.d = d;
nstates = model.nstates;
if isempty(model.A)
    model.A  = normalize(rand(nstates, nstates) + model.transPrior -1, 2);
end
if isempty(model.emission)
    % Fit on random perturbations of the data, ignoring temporal structure.
    stackedData = cell2mat(data')';
    emission = cell(nstates, 1);
    if restartNum == 1 % we initialize using a mixture of Gaussians
        mixModel = mixGaussFitEm(stackedData, nstates, 'verbose', false);
        mu = mixModel.mu;
        Sigma = mixModel.Sigma;
        for k=1:nstates
            emission{k}.mu = mu(:, k)';
            emission{k}.Sigma = Sigma(:, :, k) + eye(d);
        end
        if isempty(model.pi)
            model.pi = rowvec(mixModel.mixweight);
        end
    else
        emission = cell(nstates, 1);
        for i=1:nstates
            emission{i} = gaussFit(stackedData + randn(size(stackedData)));
        end
    end
    model.emission = emission;
end
if isempty(model.pi)
    model.pi = normalize(rand(1, nstates) +  model.piPrior -1);
end
end

function model = initDiscrete(model, data, restartNum) %#ok
% Initialize the model
model.d = 1;
model.nObsStates = nunique(cell2mat(data')');
nstates = model.nstates;
nObsStates = model.nObsStates;
if isempty(model.emissionPrior)
    model.emissionPrior = 2*ones(nstates, model.nObsStates);
end
if isempty(model.pi)
    model.pi = normalize(rand(1, nstates) + model.piPrior);
end
if isempty(model.A)
    model.A = normalize(rand(nstates, nstates) + model.transPrior, 2);
end
if isempty(model.emission)
    model.emission = normalize(rand(nstates, nObsStates), 2);
end
end
%% ESTEP
function [ess, loglik] = estep(model, data, emissionEstep)
% Compute the expected sufficient statistics.
stackedData   = cell2mat(data')';
seqidx        = cumsum([1, cellfun(@(seq)size(seq, 2), data')]);
seqidx        = seqidx(1:end-1);
nstacked      = size(stackedData, 1);
nstates       = model.nstates;
startCounts   = zeros(1, nstates);
transCounts   = zeros(nstates, nstates);
weights       = zeros(nstacked, nstates);
loglik = 0;
A = model.A;
nobs = numel(data);
for i=1:nobs
    obs = data{i}';
    [gamma, llobs, alpha, beta, B] = hmmInferState(model, obs);
    loglik = loglik + llobs;
    xi_summed = hmmComputeTwoSlice(alpha, beta, A, B);
    startCounts = startCounts + gamma(:, 1)';
    transCounts = transCounts + xi_summed;
    sz  = size(gamma, 2);
    idx = seqidx(i);
    ndx = idx:idx+sz-1;
    weights(ndx, :) = weights(ndx, :) + gamma';
end
logprior = log(A(:)+eps)'*(model.transPrior(:)-1) + ...
    log(model.pi(:)+eps)'*(model.piPrior(:)-1);
loglik = loglik + logprior;
ess = structure(weights, startCounts, transCounts);
[ess, logEmissionPrior] = emissionEstep(model, ess, stackedData);
loglik = loglik + logEmissionPrior;
end

function [ess, logprior] = estepGaussEmission(model, ess, stackedData)
% Perform the Gaussian emission component of the estep.
d = model.d;
nstates = model.nstates;
weights = ess.weights;
wsum    = sum(weights, 1);
xbar    = bsxfun(@rdivide, stackedData'*weights, wsum); %d-by-nstates
XX      = zeros(d, d, nstates);
for j=1:nstates
    Xc = bsxfun(@minus, stackedData, xbar(:, j)');
    XX(:, :, j) = bsxfun(@times, Xc, weights(:, j))'*Xc/wsum(j);
end
ess.xbar = xbar;
ess.XX = XX;
ess.wsum = wsum;
logprior = nstates*sum(gaussInvWishartMarginalLogprob...
    (model.emissionPrior, stackedData));
end

function [ess, logprior] = estepDiscreteEmission(model, ess, stackedData)
% Perform the discrete emission component of the estep.
%
% Since we've computed the weights already, we operate with all of
% observation sequences in one long vector: stackedData. The actual
% sequence lengths, (which can vary) only affect the computation of pi, A,
% and weights, not the weighted emission counts: dataCounts.
%
% ess.weights is n-by-nstates, where n is the length of stackedData. S is a
% n-by-nObsStates sparse binary matrix s.t. S(i, j) = 1 iff
% stackedData(i) == j and acts as an indicator function. The weights'*S
% matrix multiply sums the entries in weights according to S, resulting in
% an nstates-by-nObsStates dataCounts matrix: dataCounts(h, o) is equal to
% the weighted (i.e. expected) count of the joint occurance of hidden
% state h and observed state o, which will be normalized so that rows sum
% to one in the maximization step.
logprior = log(model.emission(:)+eps)'*(model.emissionPrior(:)-1);
weights = ess.weights;
S = bsxfun(@eq, stackedData(:), sparse(1:model.nObsStates));
ess.dataCounts = weights'*S; % dataCounts is nstates-by-nObsStates
ess.wsum = sum(weights, 1)';
end
%% MSTEP
function model = mstepGauss(model, ess)
%% Maximize
model.pi = normalize(ess.startCounts + model.piPrior -1);
model.A  = normalize(ess.transCounts + model.transPrior -1, 2);
xbar     = ess.xbar;
XX       = ess.XX;
nstates  = model.nstates;
prior    = model.emissionPrior;
m0 = prior.mu(:);
S0 = prior.Sigma;
v0 = prior.dof;
k0 = prior.k;
n  = size(ess.weights, 1);
kn = k0 + n;
vn = v0 + n;
d  = model.d;

emission = cell(1, nstates);
for k=1:nstates
    xbark   = xbar(:, k);
    XXk     = XX(:, :, k);
    xbarkM0 = xbark - m0;
    Sn      = S0 + n*XXk + (k0*n)./(k0+n).*(xbarkM0*xbarkM0');
    mn      = (k0*m0 + n*xbark)./kn;
    %% map estimate
    emission{k}.mu    = mn;
    emission{k}.Sigma = Sn ./(vn + d + 2);
end
model.emission = emission;
end

function model = mstepDiscrete(model, ess)
%% Maximize
model.pi = normalize(ess.startCounts + model.piPrior -1);
model.A  = normalize(ess.transCounts + model.transPrior -1, 2);
Epc = model.emissionPrior - 1;
denom = ess.wsum + sum(Epc, 2);
model.emission = bsxfun(@rdivide, ess.dataCounts + Epc, denom);
end