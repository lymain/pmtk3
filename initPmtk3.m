function initPmtk3(verbose)
%% Run this script to initialize PMTK3

% This file is from pmtk3.googlecode.com

format compact
more   off; % especially important in Octave - init may fail without it
if nargin < 1
    verbose = true; 
end
if verbose
    disp('initializing pmtk3'); 
end
%% check if this is matlab or octave
isMatlab = ~isempty(ver('matlab')); 
if ~isMatlab
   initPmtk3Octave(); % we may have some duplication this way
                      % but it is much easier to debug. 
   return;
end
include  = @(d, varargin)addpath(genpathPMTK(d, isMatlab), varargin{:}); 
%% change to the directory storing this function, (should be PMTK3 root).
w = which(mfilename()); 
thisDir = fileparts(w);
cd(thisDir);
addpath(thisDir);
%% include localUtil
include(fullfile(thisDir, 'localUtil')); 
%% include matlab tools
mtSource = getConfigValue('PMTKlocalMatlabToolsPath');
if exist(mtSource, 'dir') % if local svn repository exists, use it
    include(mtSource); 
else
    include(fullfile(thisDir, 'matlabTools')); 
end
if ~exist('matlabToolsRoot', 'file')
    url = 'http://matlabtools.googlecode.com/svn/trunk/matlabTools.zip';
    fprintf('downloading matlabTools.............'); 
    unzip(url, fullfile(thisDir, 'matlabTools')); % download from googleCode 
    include(fullfile(thisDir, 'matlabTools')); 
    fprintf('done\n'); 
end
%% include core PMTK3 directories
include(fullfile(thisDir, 'toolbox')); 
include(fullfile(thisDir, 'demos')); 
include(fullfile(thisDir, 'data'));             % may be initially empty
include(fullfile(thisDir, 'external')); % may be initially empty
if exist(fullfile(thisDir, 'docs', 'tutorial'), 'dir')
    include(fullfile(thisDir, 'docs', 'tutorial')); 
end
%% we store user / system specific pmtk info in the systemInfo directory 
pmtkInfoDir = fullfile(thisDir, 'localUtil', 'systemInfo');
%% write isOctave function
text = { 'function answer = isOctave()'
         '%autogenerated by initPmtk3()'
              sprintf('answer = %d;', ~isMatlab);
         'end'
        };
writeText(text, fullfile(pmtkInfoDir, 'isOctave.m'));
%% write is*ToolboxInstalled functions
toolbox = {'stats', 'bioinfo', 'optim', 'signal', 'images', 'symbolic',...
    'nnet', 'splines'};
for t=1:numel(toolbox)
    if isMatlab
        installed = ...
            onMatlabPath(fullfile(matlabroot, 'toolbox', toolbox{t}), true);
    else
        installed = false;
    end
    fname =   sprintf('%sToolboxInstalled', toolbox{t});
    text  = { sprintf('function answer = %s()', fname)
        '% autogenerated by initPmtk3()'
        sprintf('answer = %d;', installed)
        'end'
        };
    writeText(text, fullfile(pmtkInfoDir, [fname, '.m']));
end
%% include PMTK support
source = getConfigValue('PMTKlocalSupportPath');
if exist(source, 'dir')
    include(source); 
end
if ~(exist('pmtkSupportRoot', 'file') == 2)
    downloadAllSupport();
end
%% include graphViz 
if  ~verLessThan('matlab', '7.6.0')
    gvizDir = getConfigValue('PMTKgvizPath'); 
    if exist(gvizDir, 'dir')
       addtosystempath(gvizDir);  
    end
end
%% add the svm executables to the system path.
if exist('pmtkSupportRoot', 'file')
    folder = pmtkSupportRoot(); 
    dirs   = {'svmLightWindows'        , ...
             'liblinear-1.51\windows' , ...
             'libsvm-mat-2.9.1'};
           %  'mplp-1.0'};
    for i=1:length(dirs)
        addtosystempath(fullfile(folder, dirs{i}))
    end
end
%% add local data directory to path if it exists
source = getConfigValue('PMTKlocalDataPath');
if exist(source, 'dir')
    include(source); 
end
%% compile mex
if false % automated compilation does not work on all systems since the
         % Matlab versions for these OSs do not come with a built in
         % compiler, e.g. 64bit windows.
    
    % We use the existence of the 'mexDone.txt' as a marker so that we only
    % check for uncompiled mex files the first time this is run.
    if isMatlab
        alreadyIncluded = {'mexw32', 'mexglx'}; % compiled files are already included for these types
        checkFile =  fullfile(pmtk3Root(), 'localUtil', 'mexDone.txt');
        if ~ismember(mexext(), alreadyIncluded) && ~exist(checkFile, 'file')
            installLightspeedPMTK();
            compileC(pmtk3Root()); % does not compile external packages, most of which require special linkage
            writeText({'Autogenerated by initPmtk3'}, checkFile);
        end
    end
end
%%
if verbose, 
    disp('welcome to pmtk3'); 
end
end


function initPmtk3Octave()
%% Initialize PMTK3 for Octave
w = which(mfilename());
if w(1) == '.' % for octave compatability
    w = fullfile(pwd, w(3:end));
end
thisDir = fileparts(w);
cd(thisDir);
restoredefaultpath();
addpath(genpath(pwd));
if ~exist('matlabToolsRoot', 'file')
    url = 'http://matlabtools.googlecode.com/svn/trunk/matlabTools.zip';
    fprintf('downloading matlabTools.............');
    dest = fullfile(thisDir, 'matlabTools', 'matlabTools.zip');
    downloadFile(url, dest);       % more reliable than unzip(url, ...
    unzip(dest, fileparts(dest)); 
    addpath(genpath(fullfile(thisDir, 'matlabTools')));
    fprintf('done\n');
end
%%
pmtkInfoDir = fullfile(thisDir, 'localUtil', 'systemInfo');
%% write isOctave function
text = { 'function answer = isOctave()'
    '%autogenerated by initPmtk3()'
    sprintf('answer = 1;');
    'end'
    };
writeText(text, fullfile(pmtkInfoDir, 'isOctave.m'));
%% write is*ToolboxInstalled functions
toolbox = {'stats', 'bioinfo', 'optim', 'signal', 'images', 'symbolic',...
    'nnet', 'splines'};
for t=1:numel(toolbox)
    fname =   sprintf('%sToolboxInstalled', toolbox{t});
    text  = { sprintf('function answer = %s()', fname)
              '% autogenerated by initPmtk3()'
               sprintf('answer = 0;')
              'end'
            };
    writeText(text, fullfile(pmtkInfoDir, [fname, '.m']));
end
%% include PMTK support
if ~(exist('pmtkSupportRoot', 'file') == 2)
    downloadAllSupport();
end
restoredefaultpath();
addpath(genpath(pwd));  % octave path management can be buggy - make sure
disp('welcome to pmtk3');
end
