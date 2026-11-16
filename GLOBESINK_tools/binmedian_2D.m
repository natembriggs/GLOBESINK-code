function [x_mat, y_mat, z_mat, n_mat] = binmedian_2D(x,y,z,x_edges,y_edges)
% [x_mat, y_mat, z_mat, n_mat] = binmedian_2D(x,y,z,x_edges,y_edges)
% 
% x_edges: values separating x bins
% y_edges: values separating y bins

notnan = ~isnan(x) & ~isnan(y) & ~isnan(z);
x = x(notnan); y = y(notnan); z = z(notnan);

m = length(y_edges)-1;
n = length(x_edges)-1;

x_mat = nan(m,n);
y_mat = nan(m,n);
z_mat = nan(m,n);
n_mat = zeros(m,n);

for x_ix = 1:n
    for y_ix = 1:m
        g = x>=x_edges(x_ix)&x<x_edges(x_ix+1) &...
            y>=y_edges(y_ix)&y<y_edges(y_ix+1);
        if any(g)
            z_mat(y_ix,x_ix) = mean(z(g));
            x_mat(y_ix,x_ix) = mean(x(g));
            y_mat(y_ix,x_ix) = median(y(g));
            n_mat(y_ix,x_ix) = sum(g);
        end
    end
end