function I = pmtkTagReport(root)
%% Gather info on all of the tags in the PMTK3 system.
% I is a struct with the following fields:
%   files............a list of all of the PMTK3 files with at least one tag
%   tags.............tags{i} are the tags for files{i}
%   tagtext..........tagtext{i}{j} is the remaining text after tag{j} in 
%                    files{i}.
%   codelen..........codelen(i) is the number of non-blank lines in 
%                    files{i}. If files{i} is a Contents.m files, then 
%                    codelen is the code length of all of the files in the 
%                    containing directory structure.
%   fulltext.........fulltext{i}{j} is the jth line of files{i} (includes 
%                    blank lines)
%   authors..........authors{i}{j} is the jth author of files{i}
%   nfiles...........the number of files in the report.
%   tagmap...........tagmap.(tag) returns a cell array of all of the files 
%                    with this tag.
%   filendx..........filendx(filename) returns the index of the filename in
%                    files.
%   hastag...........hastag(f, tag) = true iff file f has the tag.
%   authorlist.......a list of all of the authors found
%   contribution.....contribution(j) is the total contribuion in lines of
%                    code by authorlist{j} - sorted in descending order
%   isauthor.........isauthor(i, j) = true iff authorlist(j) is an author
%                    of files{i}.
%   iscontents.......iscontents(i) = true iff files{i} is a Contents.m file
%   isbinary.........isbinary(i) = true iff files{i} is a Contents.m files
%                    and there are executable, *.exe, or *.bin files in the 
%                    containing directory structure. 
%%
%
if nargin < 1, root = pmtk3Root(); end
%% Get a list of all  files
files = mfiles(root(), 'usefullpath', true);
%% Get the tags, tagtext codelen and full text of all of these files
[tags, tagtext, codelen, fulltext]  ...
    = cellfun(@tagfinder, files, 'uniformoutput', false);
%% Remove files with no tags
remove           = cellfun(@isempty, tags);
files(remove)    = [];
tags(remove)     = [];
tagtext(remove)  = [];
codelen(remove)  = [];
fulltext(remove) = [];
%% Standardize tag names, PMTKremainingtagname
tags = cellfunR(@(c)[upper(c(1:4)), lower(c(5:end))], tags);
%% Determine code length for packages
codelen = cell2mat(codelen);
iscontents = cellfun(@(f)isSubstring('-meta.m', f), files);
codelen(iscontents) = cellfun(@(c)countLinesOfCodeDir(...
    fileparts(c), false, true), files(iscontents));
nfiles = numel(files);
isbinary = false(nfiles, 1); 
isbinary(iscontents) = cellfun(@(f)~isempty(filelist(fileparts(f), ...
    {'*.exe', '*.bin'})), files(iscontents));
%% Build tag map
tagmap = struct();
for i=1:nfiles
    for j=1:numel(tags{i})
        tag = tags{i}{j};
        if ~isfield(tagmap, tag)
            tagmap.(tag) = {};
        end
        val = tagmap.(tag);
        val = insertEnd(files{i}, val);
        tagmap.(tag) = val;
    end
end
%% Create helper functions
filendx  = @(f)cellfind(files, f);
hastag   = @(f, tag)ismember(tag, tags(filendx(f)));
%% Determine file authors
excluded = tokenize(getConfigValue('PMTKauthors'), ',')';
authors = cell(nfiles, 1);
for i=1:nfiles
    j = cellfind(tags{i}, 'PMTKauthor');
    if ~isempty(j)
        j = j(1); 
        alist = setdiff(strtrim(tokenize(tagtext{i}{j}, ',')), excluded);
        if ~isempty(alist)
           authors{i} = colvec(alist);  
        end
    end
end
authorlist = unique(vertcat(authors{:}));
isauthor = false(nfiles, numel(authorlist));
for i=1:nfiles
    for j=1:numel(authorlist)
        if isempty(authors{i}), continue; end
        isauthor(i, j) = ismember(authorlist{j}, authors{i}); 
    end
end
contribution = sum(bsxfun(@times, codelen, isauthor), 1)';
[contribution, perm] = sort(contribution, 'descend'); %#ok
isauthor = isauthor(:, perm); 
authorlist = authorlist(perm); 

bincontrib = any(bsxfun(@and, isauthor, isbinary), 1); 

%% Return report
I = structure(files, tags, tagtext, tagmap, filendx, nfiles,...
    hastag, codelen, fulltext, authors, authorlist, isauthor,...
    contribution, iscontents, isbinary, bincontrib);
end