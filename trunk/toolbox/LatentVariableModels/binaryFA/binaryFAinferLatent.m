function [muPost, SigmaPost] = binaryFAinferLatent(model, data, varargin)
% Infer distribution over latent factors given observed data
%
% data(n,j) in {0,1} or {1,2}
% NaN's not supproted
%
%
% Output:
% mu(:,n)
% Sigma(:,:,n)
% loglikCases(n)

[N,T] = size(data);
y = canonizeLabels(data)-1; % {0,1}
W = model.W;
b = model.b;
[K, T2] = size(W);
muPrior = zeros(K,1);
SigmaPrior = eye(K,K);
muPost = zeros(K,N);
SigmaPost = zeros(K,K,N);
for n=1:N
  [muPost(:,n), SigmaPost(:,:,n)] = ...
    varInferLogisticGauss(y(n,:), W, b, muPrior, SigmaPrior);
end


end

