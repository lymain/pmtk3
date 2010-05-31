function generateSynopses()
%% Generate the synopses listing files and one line desriptions
% PMTKneedsMatlab

wikiFile = 'C:\pmtk3wiki\synopsisPages.wiki';
dest = fullfile(pmtk3Root(), 'docs', 'synopsis'); 
%% Toolbox
d = dirs(fullfile(pmtk3Root(), 'toolbox')); 
for i=1:numel(d)
   generateSynopsisTable(fullfile(pmtk3Root(), 'toolbox', d{i}), ...
                     fullfile(dest, sprintf('%s.html', d{i})));
    
end
%% Util
generateSynopsisTable(fullfile(pmtk3Root(), 'misc', 'util'), fullfile(dest, 'util.html'));
%% Meta Tools
generateSynopsisTable(fullfile(pmtk3Root(), 'misc', 'metatools'), fullfile(dest, 'metatools.html'));
googleRoot = 'http://pmtk3.googlecode.com/svn/trunk/docs/synopsis';
wikiText = cell(numel(d), 1);
for i=1:numel(d)
    if exist(fullfile(dest, [d{i}, '.html']), 'file')
        wikiText{i} = sprintf(' * [%s/%s.html %s]',googleRoot, d{i}, d{i});
    end
end
wikiText = filterCell(wikiText, @(c)~isempty(c));
wikiText =  [{
             '#summary Synopses of the main PMTK3 functions'
             'auto-generated by generateSynopses'
             ''
             ''
             ''
             ''
             'This page lists the main folders within PMTK. Click on the link to see the list of files in that folder, with a brief description. Click on the file to see its'
             'source code, including comments on how to use it.'
             ''
             }
            {'== toolbox =='
            ''
            'Most of the main PMTK functions are here. There is one folder per book chapter.'
            ''
            ''
             };
            wikiText
            {
            ''
            ''
            '== misc =='
            'Some miscellaneous functions are stored here. util are generally useful matlab functions, metatools are functions related to "meta" issues, such as'
            'automatically creating this documentation. Other misc folders are included in pmtk but are not listed here.'
            ''
            ''
            sprintf(' * [%s/%s.html %s]', googleRoot, 'util', 'util');
            sprintf(' * [%s/%s.html %s]', googleRoot, 'metatools', 'metatools');
            }];
            
writeText(wikiText, wikiFile); 
end