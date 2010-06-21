function installPmtkSupport()
%% Download pmtkSupport packages from pmtkSupport.googlecode.com

source = getConfigValue('PMTKsupportLink'); 
destFolder = fullfile(pmtk3Root, 'external');
destFile   = fullfile(destFolder, 'pmtkSupport.zip');
fprintf('downloading pmtkSupport packages...');
if ~isPerlInstalled()
    error('loadData:noPerl', 'This script requires perl, please install it, or download the pmtkSupport packages manually from <a href ="%s">here.</a>', source);
end
ok = downloadFile(source, destFile);
if ok
    try
        unzip(destFile, destFolder);
        delete(destFile);
        fprintf('done\n')
    catch %#ok
        fprintf('\n\n');
        error('installPmtkSupport:postDownloadError', 'The PMTK support packages were found, but could not be unzipped');
    end
else
    fprintf('\n\n');
    error('installPmtkSupport:fileNotFound', 'The PMTK support packages could not be downloaded');
end
addpath(genpathPMTK(destFolder), '-end'); 
end