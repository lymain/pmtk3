function idx = firstTrue(boolarray)
% Returns the linear index of the first true element found or 0 if none
% found. 


    idx = find(boolarray);
    if ~isempty(idx);
        idx = idx(1);
    else
        idx = 0;
    end
    
end