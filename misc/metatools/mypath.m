function p = mypath()
% Returns a cell array of all of the non-matlab directories on your matlab
% path. 
p = tokenize(path, ';'); 
p = p(~strncmp(matlabroot, p, length(matlabroot)));
p = filterCell(p, @(s)~isSubstring('.svn', s));
p = [p; pwd];

end