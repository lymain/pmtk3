function publishFolder(folder, wikiOnly)
% Publish a single demos directory, (called by publishDemos)
%
%% Example
%
% publishFolder bayesDemos
%
%%
SetDefaultValue(2, 'wikiOnly', false); 
warnState = warning('query', 'all'); 
warning off all
cleaner = onCleanup(@(x)cleanup(warnState)); 
shadowFunction({'pause', 'keyboard', 'input', 'placeFigures'}, [], true);
%% Settings
% Demos with these tags have only their text published, they are not run.
doNotEvalList = {'PMTKinteractive', 'PMTKbroken', 'PMTKreallySlow'};
globalEval    = true; % if false, no code is evaluated during publishing.
googleRoot    = sprintf('http://code.google.com/p/pmtk3/source/browse/trunk/demos/%s/', folder);
dest          = fullfile(pmtk3Root(), 'docs', 'demoOutput');
%% Make sure the folder is non-empty
if (isempty(mfiles(fullfile(pmtk3Root(), 'demos', folder))));
    fprintf('%s is empty\n', folder);
    return
end
if ~exist(fullfile(dest, folder), 'file')
    mkdir(fullfile(dest, folder));
end
%% Get the PML page references, if any, and create a lookup table. 
[PMLrefs, PMLpages, datestr] = pmlCodeRefs();
PMLrefs   = cellfuncell(@genvarname, PMLrefs);
PMLlookup = createStruct(PMLrefs, PMLpages);
%% Get a list of all of the demos in the folder
demos = mfiles(fullfile(pmtk3Root(), 'demos', folder));
%% Gather info about the demos, and then publish. 
info = createStruct({'name', 'description', 'doEval', 'localLink', 'googleLink', 'tagstr'});
cd(dest);
for i=1:numel(demos)
    info(i) = mfileInfo(demos{i});
    if ~wikiOnly
        publishFile(demos{i}, fullfile(dest, folder), info(i).doEval);
    end
end
%% Write the index page
%
%% Sort the demos alphabetically
perm = sortidx(cellfuncell(@(str)lower(str),{info.name}));
sortedInfo = info(perm);
%%
fid = setupHTMLfile(fullfile(folder, 'index.html'), folder, datestr);
setupTable(fid, ...
    {'File Name', 'Brief Description', 'Page Number(s)', 'Tags'}, ...
    [25, 55, 10, 10]);
lprintf = @(link, name)fprintf(fid, '\t<td> <a href="%s"> %s </td>\n', link, name);
for i=1:numel(sortedInfo)
    fprintf(fid,'<tr bgcolor="white" align="left">\n');
    fprintf(fid, '<td>%s</td>\n', sortedInfo(i).name);
    %lprintf(sortedInfo(i).googleLink, sortedInfo(i).name);
    lprintf(sortedInfo(i).localLink, sortedInfo(i).description);
    name = sortedInfo(i).name;
    if isfield(PMLlookup, name)
        pgs = PMLlookup.(name);
        if numel(pgs) == 1,
            pgstr = num2str(pgs);
        else
            pgstr = catString(cellfuncell(@num2str, num2cell(pgs)), ', ');
        end
        fprintf(fid, '<td>%s</td>\n',  pgstr);
    else
        fprintf(fid, '<td>&nbsp;</td>\n');
    end
    fprintf(fid, '<td>%s</td>\n', sortedInfo(i).tagstr);
    fprintf(fid,'</tr>\n');
end
fprintf(fid,'</table>');
closeHTMLfile(fid);
%%
    function info = mfileInfo(mfile)
        % gather info about the mfile    
        info.name = mfile(1:end-2);
        h = help(mfile);
        if isempty(h)
            info.description = '&nbsp;';
        else
            h = tokenize(h, '\n');
            info.description = h{1};
        end
        tags = tagfinder(mfile); 
        info.doEval = globalEval && isempty(intersect(tags, doNotEvalList));
        info.localLink = [info.name, '.html'];
        info.googleLink = [googleRoot, mfile];
        tagstr = {};
        if ismember('PMTKbroken', tags)
            tagstr = [tagstr, 'X'];
        end
        if ismember('PMTKneedsStatsToolbox', tags)
            tagstr = [tagstr, {'S'}]; 
        end
        if ismember('PMTKneedsOptimToolbox', tags)
            tagstr = [tagstr, {'O'}]; 
        end
        if ismember('PMTKneedsBioToolbox', tags)
            tagstr = [tagstr, {'B'}]; 
        end
        if ismember('PMTKneedsMatlab', tags)
            tagstr = [tagstr, {'M'}]; 
        end
        if ismember('PMTKinteractive', tags)
            tagstr = [tagstr, 'I'];
        end
        if ismember('PMTKslow', tags)
            tagstr = [tagstr, '*'];
        end
        if ismember('PMTKreallySlow', tags)
            tagstr = [tagstr, '**'];
        end
        info.tagstr = catString(tagstr, ' ');
        if isempty(info.tagstr)
            info.tagstr = '&nbsp;';
        end
    end
end

function publishFile(mfile, outputDir, evalCode)
% Publish an m-file to the specified output directory.
options.evalCode = evalCode;
options.outputDir = outputDir;
options.format = 'html';
options.createThumbnail = false;
publish(mfile, options);
evalin('base','clear all');
close all hidden;
end


function fid = setupHTMLfile(fname, folder, datestr)
% Setup a root HTML file
d = date;
fid = fopen(fname,'w+');
fprintf(fid,'<html>\n');
fprintf(fid,'<head>\n');
fprintf(fid,'<font align="left" style="color:#990000"><h2>PMTK3: %s</h2></font>\n', folder);
fprintf(fid,'<br>Revision Date: %s \n<br> Book Version: %s<br>\n',d, datestr);
fprintf(fid,'<br>Auto-generated by publishDemos.m<br>\n');
fprintf(fid, '<br>Click on a link in the second column to go to a page showing the source code and the output that the function generates.<br>');
fprintf(fid, 'Some demos are tagged according to the table on the right.<br><br>\n');  

tableData = {'S' , 'stats toolbox needed',           'I' , 'interactive'
             'B' , 'bioinformatics toolbox needed',  'M' , 'matlab  needed, (will not work in octave)'
             'O' , 'optimization toolbox needed',    'W' , 'windows needed, (will not work in linux)'
             'X' , 'currently broken'           ,    '*'  ,  'slow (two stars indicates very slow)'
             };

t = htmlTable('data', tableData, 'dosave', false, 'doshow', false,...
             'dataAlign', 'left', 'tableAlign', 'right');
fprintf(fid, t); 
fprintf(fid,'\n</head>\n');
fprintf(fid,'<body>\n\n');
fprintf(fid,'<br>\n');
end

function closeHTMLfile(fid)
% Close a root HTML file
fprintf(fid,'\n</body>\n');
fprintf(fid,'</html>\n');
fclose(fid);
end

function setupTable(fid,names,widths)
% Setup an HTML table with the specified field names and widths in percentages
fprintf(fid,'<table width="100%%" border="3" cellpadding="5" cellspacing="2" >\n');
fprintf(fid,'<tr bgcolor="#990000" align="center">\n');
for i=1:numel(names)
    fprintf(fid,'\t<th width="%d%%">%s</th>\n', widths(i), names{i});
end
fprintf(fid,'</tr>\n');
end

function cleanup(warnState)
    warning(warnState); 
    removeShadows(true);
end

