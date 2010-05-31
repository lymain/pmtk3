function str = removeExtraSpaces(str)
% Replace all contiguous sequences of spaces with a single space
if isempty(str); return; end
prev = str;
str = strrep(str, '  ', ' ');
while ~strcmp(str, prev)
    prev = str;
    str = strrep(str, '  ', ' ');
end

end