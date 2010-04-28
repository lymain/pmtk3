function A = padOnes(data, ndx, sz)
% Returns a vector or matrix with dimensions sz, with oness everywhere
% except at linear indices ndx, where the corresponding entry from data
% is put. 
    if isscalar(sz)
        sz = [sz, 1]; 
    end
    A = ones(sz);
    A(ndx) = colvec(data);
end