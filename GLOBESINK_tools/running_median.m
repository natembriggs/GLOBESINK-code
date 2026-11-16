function y_filt = running_median(varargin)
% y_filt = running_median(y,n,compute_edges);
%
% applies a median filter to a series of data "y" with window size "n".
% Window size should be an odd number
% NANs are ignored unless more than half of the datapoints within the
% window are NANs. In this case, "y_filt" is set to NAN. Filter width is
% reduced to ciel(n/2) at edges.
%
% INUPTS:
%                    y: variable to filter
%                    n: window size
%        compute_edges: boolean flag to compute medians with partial window
%                       at edges (1, default) or fill edges with nans (0)
% OUTPUTS:
%               y_filt: filtered timeseries
%
% by Nathan Briggs
% last modified 24 Nov 2015
if length(varargin)>=3
    REMOVENAN = varargin{3};
else
    REMOVENAN = 1;
end
y = varargin{1}; n = varargin{2};

 
if n==1
    y_filt = y;
else
    row_vector = size(y,2) > size(y,1);
    if row_vector
        y = y';
    end
    
    % MAIN FILTER
    
    % set up matrix
    y_mat = nan(n,length(y)+1-n);
    for ii = 1:n
        y_mat(ii,:) = y(ii:end-n+ii);
    end
    % take the median
    y_filt = nanmedian(y_mat);
    
    
    % EDGES
    leg = (n-1)/2;
    start_segment = nan(1,leg);
    end_segment = nan(1,leg);
 
    if REMOVENAN==1
        for ii = 1:leg
            if sum(~isnan(y(1:ii+leg)))>n/2
                start_segment(ii) = nanmedian(y(1:ii+leg));
            end
            if sum(~isnan(y(end-2*leg+ii:end)))>n/2
                end_segment(ii) = nanmedian(y(end-2*leg+ii:end));
            end
        end
        
    start_segment(ii) = nanmedian(y(1:ii+leg));
    end_segment(ii) = nanmedian(y(end-2*leg+ii:end));
 
                        
        % set NANs
    y_filt(sum(isnan(y_mat),1)>n/2) = nan;
    end
 
    y_filt = [start_segment y_filt end_segment]';
    
    if row_vector
        y_filt = y_filt';
    end
end