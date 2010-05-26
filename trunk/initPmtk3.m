function initPmtk3()
%% Run this script to initialize PMTK3
disp('initializing pmtk3');
format compact
%%
% Change to the directory storing this function, which should be the
% root PMTK3 directory.
cd(fileparts(which(mfilename())));
%%
% Add PMTK3 to the Matlab path
addpath(genpathPMTK(pwd));
%%
% We store user specific pmtk info in a directory they are sure to have
% write access to.
pmtkInfoDir = fullfile(tempdir(), 'pmtkInfo');
if ~exist(pmtkInfoDir, 'file')
    mkdir(pmtkInfoDir);
end
providePath(pmtkInfoDir);
%%
% Store information about which toolboxes are installed
toolbox = {'stats', 'bioinfo', 'optim', 'signal', 'images', 'symbolic',...
           'nnet', 'splines'};
for t=1:numel(toolbox)
    installed = ...
        onMatlabPath(fullfile(matlabroot, 'toolbox', toolbox{t}), true);
    fname =   sprintf('%sToolboxInstalled', toolbox{t}); 
    text  = { sprintf('function answer = %s()', fname)
              '% autogenerated by initPmtk3()'
              sprintf('answer = %d;', installed)
             'end'
            };
    writeText(text, fullfile(pmtkInfoDir, [fname, '.m'])); 
end
%%
% Check if this is Octave or Matlab
matlab = isSubstring('MATLAB', matlabroot, true); 
text = { 'function answer = isOctave()'
         '%autogenerated by initPmtk3()'
         sprintf('answer = %d;', ~matlab); 
         'end'
       };  
writeText(text, fullfile(pmtkInfoDir, 'isOctave.m')); 
%%
% If running windows, add the svm executables to the system path.
if ispc()
    folder = fullfile(pmtk3Root(), 'toolbox',...
        'Kernel_methods_for_supervised_learning');
    
    dirs = {'svmLightWindows'        , ...
            'liblinear-1.51\windows' , ...
            'libsvm-mat-2.9.1'       };
        
    for i=1:length(dirs)
        addtosystempath(fullfile(folder, dirs{i}))
    end
end
end