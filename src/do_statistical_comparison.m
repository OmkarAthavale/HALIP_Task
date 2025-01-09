function [h, p, s] = do_statistical_comparison(x, y, noPrint)
n1 = inputname(1); n2 = inputname(2);
if (length(x) == length(y)) && nnz(~isnan(x-y)) > 1
    n = [nnz(~isnan(x-y)), nnz(~isnan(x-y))];
    try
        normalTest = (swtest(x-y)-1)*-1;
        if nargin < 3
            fprintf('Is normal: %d\n', normalTest)
        end
    catch
        warning('Not enough obs for normality check')
    end
    [h, p, s] = ttest(x, y);
    %     [p, h] = signtest(x, y);
    if nargin < 3
        
        write_statistics(x(~isnan(x-y)), n1, '')
        type = 'Paired';
        write_statistics(y(~isnan(x-y)), n2, '')
    end
else
    n = [ nnz(~isnan(x)),  nnz(~isnan(y))];
    [h, p, s] = ttest2(x, y);
    h = h*-1;
    type = 'Two-sample';
    if nargin < 3
        
        write_statistics(x, n1, '')
        write_statistics(y, n2, '')
    end
end

if nargin < 3
    fprintf('%s %s vs %s: p = %.6f; n = %d, %d\n', type, n1, n2, p, n)
end


