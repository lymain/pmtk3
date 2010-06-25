function [model, loglikHist] = hmmFit(data, nstates, type, varargin)
%% Fit an HMM model
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
[model, loglikHist] = hmmFitEm(data, nstates, type, varargin{:});