function [mu, se] = cvEstimate(fitFn, predictFn, lossFn, X, y,  Nfolds, testFolds)
% Cross validation estimate of expected loss
% model = fitFn(Xtrain, ytrain)
% yhat = predictFn(model, Xtest)
% L = lossFn(yhat, ytest), should return a vector of errors
% X is N*D design matrix
% y is N*1
% Nfolds is number of CV folds
% Alternatively, you can explicitly specify the test folds
% using testFolds(:,f) for the f'th fold
% 
% mu is expected error
% se is standard error

N = size(X,1);
if nargin < 7 || isempty(testFolds)
   randomizeOrder = false;
  [trainfolds, testfolds] = Kfold(N, Nfolds, randomizeOrder);
else
  % explicitly specify the test folds
  [nTest nFolds] = size(testFolds);
  testfolds = mat2cell(testFolds, nTest, ones(nFolds,1));
  trainfolds = cellfun(@(t)setdiff(1:N,t), testfolds, 'UniformOutput', false);
end
loss = zeros(1,N);
for f=1:length(trainfolds)
   Xtrain = X(trainfolds{f},:); Xtest = X(testfolds{f},:);
   ytrain = y(trainfolds{f}); ytest = y(testfolds{f});
   model = fitFn(Xtrain, ytrain);
   yhat = predictFn(model, Xtest);
   loss(testfolds{f}) = lossFn(yhat, ytest);
end 
mu = mean(loss);
se = std(loss)/sqrt(N);

end


