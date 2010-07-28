function mrf2 = mrfToMrf2(mrf, varargin)
%% Convert a Markov random field to a pairwise MRF
% for use by Mark Schmidt's UGM library
% See mrf2Create for additional optional args
%%
mrf2 = factorGraphToMrf2(mrfToFactorGraph(mrf), varargin{:}); 
end