function [W,mu,sigma2,evals,evecs,Xproj,Xrecon]  = ppcaFit(X,K)
% Probabilistic PCA - find MLEs
% Each row of X contains a feature vector, so X is n*d
% Each column of W is a pc basis, so W is d*k
% We also return the evecs and evals of the covariance matrix
% which are useful for efficient evaluation of ppcaLogprob
%PMTKlatentModel ppca

[evecs, Xproj, evals, Xrecon, mu] = pcaPmtk(X,K); 
[n,d] = size(X);
sigma2 = mean(evals(K+1:end));
W = evecs(:,1:K) * sqrt(diag(evals(1:K))-sigma2*eye(K));
Xproj = X*W;
Xrecon = Xproj*W' + repmat(mu, n, 1);

end