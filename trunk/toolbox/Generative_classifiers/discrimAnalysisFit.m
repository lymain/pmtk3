function params = discrimAnalysisFit(X, y, type)
% Input:
% X is an n x d matrix
% y is an n-vector specifying the class label (in range 1..C)
% type is 'linear' (tied Sigma) or 'quadratic' (class-specific Sigma)
%
% Output:
% params.type
% params.classPrior(c)
% params.mu(d,c) for feature d, class c
% params.Sigma(:,:,c) covariance for class c if quadratic
% params.SigmaPooled(:,:) if linear

[n d] = size(X);
Nclasses = length(unique(y));
params.mu = zeros(d, Nclasses);
params.Sigma = zeros(d, d, Nclasses);
params.classPrior = zeros(1, Nclasses);
SigmaPooled = zeros(d,d);
for c=1:Nclasses
    ndx = (y == c); 
    nc = sum(ndx);
    dat = X(ndx, :);
    params.mu(:,c) = mean(dat);
    params.Sigma(:,:,c) = cov(dat, 1);
    params.classPrior(c) = nc/n; 
    SigmaPooled = SigmaPooled + nc*params.Sigma(:,:,c);
end
params.SigmaPooled = SigmaPooled/n;
params.type = type;

end