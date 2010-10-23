function sub_s=subsets1(s, k)
% Creates sub-sets of a specific size from a given set
% SS = subsets1(S, k)
%
% S is the given set
% k is the required sub-sets size
%
% Example:
%
% >> ss=subsets1([1:4],3);
% >> ss{:}
% ans =
%      1     2     3
% ans =
%      1     2     4
% ans =
%      1     3     4
% ans =
%      2     3     4
%
%PMTKauthor Raanan Yehezkel
%PMTKdate 2004

% This file is from matlabtools.googlecode.com


if k<0 % special case
   error('subset size must be positive');
elseif k==0 % special case
   sub_s={[]};
else
   l=length(s);
   ss={};
   if l>=k
       if k==1 % Exit condition
           for I=1:l
               ss{I}=s(I);
           end
       else
           for I=1:l
               ss1=subsets1(s([(I+1):l]),k-1);
               for J=1:length(ss1)
                   ss{end+1}=[s(I),ss1{J}];
               end
           end
       end
   end
   sub_s=ss;
end
end

