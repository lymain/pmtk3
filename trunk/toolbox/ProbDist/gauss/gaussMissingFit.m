function [model, loglikHist] = gaussMissingFit(data, varargin)
% Find MLE of MVN when X has missing values, using EM algorithm
% data is an n*d design matrix with NaN values
% See emAlgo() for EM related optional args
% PMTKsimple gauss
[model, loglikHist] = gaussMissingFitEm(data, varargin{:});


end