function [new_x, new_y, new_n, bin_ixs] = binsum_edges(old_x,old_y,x_edges)
% [new_x, new_y, new_n, bin_ixs] = binsum_edges(old_x,old_y,x_edges)
% 
% finds sums of variable "old_y", grouped into bins of corresponding
% variable "old_x", with ranges defined by "x_edges"
%
% INPUT VARIABLES
% old_x: original x data to reference the bin sums
% old_y: original y data to bin sum
% x_edges: the boundaries between the bins to sum
%
% OUTPUT VARIABLES
% new_x: average x value for each bin
% new_y: sum of y values for each bin
% new_n: number of datapoints in each bin
% bin_ixs: for each original datapoint, this gives the bin number (if any)

rowvec = isrow(old_x);

if rowvec
    old_x = old_x';
    old_y = old_y';
end

n = length(x_edges)-1;

new_x = nan(n,1);
new_y = nan(n,size(old_y,2));
new_n = nan(n,size(old_y,2));

bin_ixs = nan(size(old_x));

for this_bin = 1:n
    good = old_x >= x_edges(this_bin) & old_x < x_edges(this_bin+1) & ~isnan(old_y);
    if any(good)
        bin_ixs(good) = this_bin;
        new_x(this_bin) = mean(old_x(good),1);
        new_y(this_bin,:) = sum(old_y(good,:),1);
        new_n(this_bin,:) = sum(good);
    end
end
    