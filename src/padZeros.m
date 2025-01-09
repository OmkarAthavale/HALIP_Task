function C = padZeros(A, value, m, n)

if nargin == 1
    m = 1;
    n = 1;
    value = 0;
elseif nargin == 2
    m = 1;
    n = 1;
    n = m;
elseif nargin == 3
    n = m;
end

[w,h] = size(A);

B = [A, value.*ones(w, n)];
C = [B; value.*ones(m, h+n)];