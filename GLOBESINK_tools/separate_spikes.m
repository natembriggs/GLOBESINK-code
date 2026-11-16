function [baseline,spikes] = separate_spikes(y,n)
% SYNTAX:
%                    [baseline,spikes] = separate_spikes(y,n);
% INUPTS:
%                    y: timeseries to filter (with equal time steps)
%                    n: window size
% OUTPUTS:
%             baseline: filtered timeseries (without spikes)
%               spikes: residuals (only spikes)
%
% This function calculates a running minimum followed by a running maximum, 
% both with window size n, returning the filtered data i
%
% last modified 15 Oct 2010
% by 
% Nathan Briggs - nathan.m.briggs@maine.edu
baseline = nan(size(y));
notnan = ~isnan(y);
baseline(notnan) = maxfilt(minfilt(y(notnan),n),n);

% correction for even windows
if ~rem(floor(n),2)
    warning('Odd window size is recommended')
    [row col] = size(y);
    if row > col
        baseline = [min(y(1:n/2)); baseline; min(y(end-n/2+1:end))];
    else
        baseline = [min(y(1:n/2)) baseline min(y(end-n/2+1:end))];
    end
end

spikes = y - baseline;

