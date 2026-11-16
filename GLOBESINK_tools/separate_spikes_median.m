function [baseline,spikes] = separate_spikes_median(y,n)
% SYNTAX:
%                    [baseline,spikes] = separate_spikes_median(y,n);
% INUPTS:
%                    y: timeseries to filter (with equal time steps)
%                    n: window size
% OUTPUTS:
%             baseline: filtered timeseries (without spikes)
%               spikes: residuals (only spikes)
%
% last modified 15 Sep 2011
% by 
% Nathan Briggs - nathan.m.briggs@maine.edu
baseline = nan(size(y));
notnan = ~isnan(y);
if sum(notnan)>=n
    baseline(notnan) = running_median(y(notnan),n);
end

% correction for even windows
if ~rem(floor(n),2)
    warning('Odd window size is recommended')
end

spikes = y - baseline;

