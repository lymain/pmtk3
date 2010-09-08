%% Compare different linear kernel classifiers on several datasets
% We need to use CV/ARD to pick lambda/C
% but at least the kernel has no hyper-params to tune...
%PMTKslow

% See also classificationShootout and classificationShootoutCvLambdaOnly

clear all
setSeed(0);

%% Data
split = 0.7;
d = 1;

if 1
loadData('soy') % 3 classes, X is 307*35
dataSets(d).X = X; 
dataSets(d).y = Y; 
dataSets(d).name = 'soy';
d=d+1;
end

if 1
loadData('fglass'); % 6 classes, X is 214*9
X = [Xtrain; Xtest];
y = canonizeLabels([ytrain; ytest]); % class 4 is missing, so relabel 1:6
dataSets(d).X = X; 
dataSets(d).y = y; 
dataSets(d).name = 'fglass';
d=d+1;
end

if 1
loadData('colon') % 2 class, X is 62*2000
dataSets(d).X = X;
dataSets(d).y = y;
dataSets(d).name = 'colon';
d=d+1;
end

if 1
loadData('amlAll'); % 2 class, X is 72*7129
X = [Xtrain; Xtest];
y = [ytrain; ytest]; 
dataSets(d).X = X;
dataSets(d).y = y;
dataSets(d).name = 'amlAll';
d=d+1;
end

dataNames = {dataSets.name};
nDataSets = numel(dataSets);

for d=1:nDataSets
  nClasses(d) = nunique(dataSets(d).y);
  X = dataSets(d).X;
  [nCases(d), nFeatures(d)] = size(X);
end
attrNames = {'nClasses', 'nFeatures', 'nCases'};

folder = fullfile(pmtk3Root(), 'data');
htmlTableSimple('data', [nClasses(:) nFeatures(:) nCases(:)], ...
  'colNames', attrNames, 'rowNames', dataNames, ...
  'format', 'int', 'fname', fullfile(folder, 'data.html') );


%% Models
methods = {'SVM', 'RVM', 'SMLR', 'RMLR', 'logregL2', 'logregL1'};
%methods = {'SVM'};

nMethods = numel(methods);

%% Main
seeds = [0,1,2];
for d=1:nDataSets
  X = dataSets(d).X;
  y = dataSets(d).y;
  
  for s=1:numel(seeds);
    setSeed(seeds(s));
  [X, y] = shuffleRows(X, y);
  X      = rescaleData(standardizeCols(X));
  N      = size(X, 1);
  nTrain = floor(split*N);
  nTest  = N - nTrain;
  Xtrain = X(1:nTrain, :);
  Xtest  = X(nTrain+1:end, :);
  ytrain = y(1:nTrain);
  ytest  = y(nTrain+1:end);
  
  for m=1:nMethods
    method = methods{m};
    tic;
    
    switch lower(method)
      case 'svm'
        Crange = logspace(-6, 1, 20); % if too small, libsvm crashes!
        model = svmFit(Xtrain, ytrain, 'C', Crange,  'kernel', 'linear');
        predFn = @(m,X) svmPredict(m,X);
        chosenC(d,m,s) = model.C
      case 'rvm'
        model = rvmFit(Xtrain, ytrain, [], 'kernelFn', @kernelLinear);
        predFn = @(m,X) rvmPredict(m,X);
      case 'smlr'
        model = smlrFit(Xtrain, ytrain,  'kernelFn', @kernelLinear);
        predFn = @(m,X) smlrPredict(m,X);
      case 'rmlr'
        model = smlrFit(Xtrain, ytrain, 'kernelFn', @kernelLinear, ...
          'regtype', 'L2');
        predFn = @(m,X) smlrPredict(m,X);
      case 'logregl2'
        model = logregFitPathCv(Xtrain, ytrain, 'regtype', 'L2');
        predFn = @(m,X) logregPredict(m,X);
      case 'logregl1'
        model = logregFitPathCv(Xtrain, ytrain, 'regtype', 'L1');
        predFn = @(m,X) logregPredict(m,X);
    end
    trainingTime(d,m,s) = toc;
    saveModel{d,m,s} = model;
    
    tic
    yHat   = predFn(model, Xtest);
    testingTime(d,m,s) = toc;
    
    nerrs  = sum(yHat ~= ytest);
    testErrRate(d,m,s) = nerrs/nTest;
    numErrors(d,m,s) = nerrs;
    maxNumErrors(d) = nTest;
  end
end
end

fprintf('test err\n');
numErrors

folder = fullfile(pmtk3Root(), 'data');
htmlTableSimple('data', median(testErrRate,3), 'colNames', methods, 'rowNames', dataNames, ...
  'format', 'float',  'fname', fullfile(folder, 'err.html'), ...
  'title', sprintf('test error rate (median over %d trials)', numel(seeds)));

fprintf('training time\n');
trainingTime
htmlTableSimple('data', median(trainingTime,3), 'rowNames', dataNames, 'colNames', methods, ...
  'format', 'float',  'fname', fullfile(folder, 'time.html'), ...
  'title', sprintf('training time in seconds (median over %d trials)', numel(seeds)));

