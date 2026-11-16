function m_out = running_sum_2D(m_in,wi,wj)
% m_out = running_sum_2D(m_in,wi,wj)
%
% 2D running median filter (ignores nans)
% 
% m_in = input matrix
% wi = vertical window (in # of rows)
% wj = horizontal window (in # of columns)

segi = wi/2-0.5; segj = wj/2-0.5;
[m,n] = size(m_in);
m_out = nan(m,n);

for ii = 1:m
    istart = max(1,ii-segi);
    iend = min(m,ii+segi);
    for jj = 1:n
        jstart = max(1,jj-segj);
        jend = min(n,jj+segj);
        sub_m = m_in(istart:iend,jstart:jend);
        m_out(ii,jj) = sum(sub_m(:));
    end
end