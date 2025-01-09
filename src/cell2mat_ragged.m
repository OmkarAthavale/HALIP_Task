function z = cell2mat_ragged(X, maxLen, dir)

if nargin < 3
    dir = 2;
end

if nargin < 2 || isempty(maxLen)
    maxLen = max(cellfun(@(x) (size(x, dir)), X));
end


z = cell2mat(cellfun(@(x) padZeros(x,NaN, 0, maxLen-length(x)),X(~cellfun(@isempty, X)), 'UniformOutput', 0)');
