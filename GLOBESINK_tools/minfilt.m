function y_filt = minfilt(y,n)
% SYNTAX:
%                    y_filt = minfilt(y,n);
% INUPTS:
%                    y: timeseries to filter (with equal time steps)
%                    n: window size
% OUTPUTS:
%               y_filt: filtered timeseries 
%
% This function calculates a running minimum with window size n
%
% last modified 29 Dec 2010
% by 
% Nathan Briggs - nathan.m.briggs@maine.edu

% make sure y is a row vector
col_vector = size(y,2) < size(y,1);
if col_vector
    y = y';
end

leg = floor((n-1)/2);
y_padded = [nan(1,leg) y nan(1,leg)];

% filter
for ii = 1:n
    y_mat(ii,:) = y_padded(ii:end-n+ii);
end
y_filt = min(y_mat);

if col_vector
    y_filt = y_filt';
end