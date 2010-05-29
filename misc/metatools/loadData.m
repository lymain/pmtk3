function varargout = loadData(dataset)
%% Load the specified dataset into the struct D, downloading it if necessary
%
% If you specify an output, as in D = loadData('foo'), all of the variables
% in the .mat file are stored in the struct D, (unless there is only one).
%
% Otherwise, these variables are loaded directly into the calling
% workspace, just like the built in load() function, as in loadData('foo');
%% Example:
%
% D = loadData('prostate'); % store data in struct D
%%
% loadData('prostate');     % load data directly into calling workspace
%%
% s = loadData('sat')       % s is a matrix since there is only one variable
%%
if isOctave(),  warning('off', 'Octave:load-file-in-path'); end
googleRoot = ' http://pmtkdata.googlecode.com/svn/trunk';
%%
dataset = filenames(dataset);
if exist([dataset, '.mat'], 'file') == 2
    D = load([dataset, '.mat']);
else % try and fetch it
    fprintf('downloading %s...', dataset);
    source = sprintf('%s/%s/%s.zip', googleRoot, dataset, dataset);
    dest   = fullfile(pmtk3Root(), 'data', [dataset, '.zip']);
    if ~isPerlInstalled()
        error('loadData:noPerl', 'This script requires perl, please install it, or download the data set manually from <a href ="%s">here.</a>', source);
    end
    ok     = downloadFile(source, dest);
    if ok
        try
            destFolder = fullfile(fileparts(dest), dataset);
            unzip(dest, destFolder);
            delete(dest);
            addpath(destFolder)
            D = load([dataset, '.mat']);
            fprintf('done\n')
        catch %#ok
            fprintf('\n\n');
            error('loadData:postDownloadError', 'The %s data set was found, but could not be loaded', dataset);
        end
    else
        fprintf('\n\n');
        error('loadData:fileNotFound', 'The %s data set could not be located', dataset);
    end
end
if nargout == 0
    names = fieldnames(D);
    for i=1:numel(names)
        assignin('caller', names{i}, D.(names{i}));
    end
else
    if numel(fieldnames(D)) == 1
        names = fieldnames(D);
        varargout{1} = D.(names{1});
    else
        varargout{1} = D;
    end
end
end