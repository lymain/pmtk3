function results = classificationShootoutFaster()
%% Compare different classification algorithms on a number of data sets
% This version is similar to classificationShootout, but uses the same
% gamma for all methods. 
%PMTKslow
%%
tic
setSeed(0);
split = 0.7; % 70% training data, 30% testing
warning('off', 'Bayes:maxIter'); % max iterations reached
dataSets = setupData();
nDataSets = numel(dataSets);

methods = {'SVM', 'RVM', 'SMLR', 'RMLR'};
nMethods = numel(methods);
results = cell(nDataSets, nMethods);

for i=1:nDataSets
    gamma = pickGamma(dataSets{i});
    fprintf('\ngamma=%g\n\n', gamma); 
    for j=1:nMethods
        fprintf('%s:%s', dataSets{i}.name, methods{j}); 
        results{i, j} = evaluateMethod(methods{j}, dataSets{i}, gamma, split);
        fprintf(':%d/%d\n', results{i, j}.nerrs, results{i, j}.nTest); 
    end
end

displayResults(results);
toc
end

function gamma = pickGamma(data)
%% Pick a value for gamma, which all of the methods will use, by cv on an svm
gammaRange = logspace(-4, 3, 100);
X = rescaleData(data.X); 
fitFn = @(X, y, gamma)svmFit(X, y, 'kernel', 'rbf', 'kernelParam', gamma);
[model, gamma] = fitCv(gammaRange, fitFn, @svmPredict, @(a, b)mean(a~=b), X, data.y);
end

function results = evaluateMethod(method, dataSet, gamma, split)
%% Evaluate the performance of a method on a given data set.
X      = rescaleData(dataSet.X); 
y      = dataSet.y;
N      = size(X, 1);
nTrain = floor(split*N);
nTest  = N - nTrain;
Xtrain = X(1:nTrain, :);
Xtest  = X(nTrain+1:end, :);
yTrain = y(1:nTrain);
yTest  = y(nTrain+1:end);

lambdaRange = logspace(-6, 1, 20);

switch method
    case 'SVM'
        
        fitFn = @(X, y, lambda)...
            svmFit(X, y, 'C', 1./lambda, 'kernelParam', gamma, 'kernel', 'rbf');
        predictFn = @svmPredict;
        doCv = true;
        
    case 'RVM'
        
        model  = rvmSimpleFit(Xtrain, yTrain, gamma);
        yhat   = rvmSimplePredict(model, Xtest);
        lambda = 0;
        nerrs  = sum(yhat ~= yTest);
        doCv   = false;
        
    case 'SMLR'
        
        fitFn = @(X, y, lambda)logregFit(X, y, ...
            'lambda' , lambda, ...
            'regType', 'L1',...
            'preproc', preprocessorCreate('kernelFn',...
            @(X1, X2)kernelRbfGamma(X1, X2, gamma)));
        predictFn = @logregPredict;
        doCv = true;
        
    case 'RMLR'
        
        fitFn = @(X, y, lambda)logregFit(X, y, ...
            'lambda' , lambda, ...
            'regType', 'L2',...
            'preproc', preprocessorCreate('kernelFn',...
            @(X1, X2)kernelRbfGamma(X1, X2, gamma)));
        predictFn = @logregPredict;
        doCv = true;
        
end

if doCv
    lossFn = @(yTest, yHat)mean(yHat ~= yTest);
    nfolds = 5;
    [model, lambda]  = fitCv(lambdaRange, fitFn, predictFn, lossFn, Xtrain, yTrain, nfolds);
    yHat   = predictFn(model, Xtest);
    nerrs  = sum(yHat ~= yTest);
end

results.method      = method;
results.dataSetName = dataSet.name;
results.nClasses    = dataSet.nClasses;
results.nFeatures   = dataSet.nFeatures;
results.nTrain      = nTrain;
results.nTest       = nTest;
results.nerrs       = nerrs;
results.gamma       = gamma;
results.lambda      = lambda;

end

function displayResults(results)
%% Display the results in a table

end



function dataSets = setupData()
%% Load various dataSets, and standardize the format

%% Crabs
loadData('crabs');
X = [Xtrain; Xtest];
y = [ytrain; ytest];
[X, y] = shuffleRows(X, y);
dataSets{1}.X = X;
dataSets{1}.y = y;
dataSets{1}.name = 'Crabs';
dataSets{1}.nClasses  = 2;
dataSets{1}.nFeatures = 5;
%% fisherIris
loadData('fisherIris');
X = meas;
y = canonizeLabels(species);
[X, y] = shuffleRows(X, y);
dataSets{2}.X = X;
dataSets{2}.y = y;
dataSets{2}.name = 'Iris';
dataSets{2}.nClasses  = 3;
dataSets{2}.nFeatures = 4;
%% Bankruptcy
loadData('bankruptcy'); 
X = data(:, 2:end); 
y = data(:, 1); 
[X, y] = shuffleRows(X, y); 
dataSets{3}.X = X;
dataSets{3}.y = y;
dataSets{3}.name = 'Bankruptcy';
dataSets{3}.nClasses  = 2;
dataSets{3}.nFeatures = 2;
%% Pimatr
loadData('pimatr')
X = data(:, 2:end-1); 
y = data(:, end); 
[X, y] = shuffleRows(X, y); 
dataSets{4}.X = X;
dataSets{4}.y = y;
dataSets{4}.name = 'Pima';
dataSets{4}.nClasses  = 2;
dataSets{4}.nFeatures = 7;
%% Soy
loadData('soy')
[X, y] = shuffleRows(X, Y); 
dataSets{5}.X = X;
dataSets{5}.y = y;
dataSets{5}.name = 'Soy';
dataSets{5}.nClasses = 3;
dataSets{5}.nFeatures = 35; 
%% Fglass
loadData('fglass');
X = [Xtrain; Xtest];
y = [ytrain; ytest];
[X, y] = shuffleRows(X, y);
dataSets{6}.X = X;
dataSets{6}.y = y;
dataSets{6}.name = 'Fglass';
dataSets{6}.nClasses  = 6;
dataSets{6}.nFeatures = 9;
end