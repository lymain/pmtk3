function f = filenames(files)
% Takes in a cell array of paths and returns only the file names
% Removes extensions as well
%
%% Example
%
% f = filenames({'C:\foo\bar1.m', 'C\foo\bar2.m'})
% f = 
%    'bar1'    'bar2'
%% 
f = cellfuncell(@(f)argout(2, @fileparts, f), files); 
end