function R = missingEnds()
% Return a list of all of the non-builtin mfiles on the matlab path that
% are missing the syntactically optional end keyword at the end of the 
% function. 

fileNames = allMfilesOnPath();
ndx = cellfun(@isEndKeywordMissing, fileNames); 
R = fileNames(ndx); 


end

