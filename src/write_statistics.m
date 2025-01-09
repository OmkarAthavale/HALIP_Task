function [varargout] = write_statistics(dat, label, unit, returnFlag)
if nargin < 4
    returnFlag = 0;
end

n = sum(~isnan(dat(:)));
mu = mean(dat(:), 'omitnan');
sigma = std(dat(:), 'omitnan');

fprintf('%s (n = %d): %.4f (%.4f) %s\n', label, n, mu, sigma, unit);

if returnFlag
    varargout = {n, mu, sigma};
end
end