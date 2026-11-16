function [yfit,slope_xs,slopes,slope_ys] = running_quantile_fit(varargin)
%[yfit,slope_xs,slopes] = running_quantile_fit(x,y,fit_int,fit_app_int,start_int,q);
% OR
% yfit = running_quantile_fit(y,fit_int,fit_app_int,start_int,q);
% in this case, x is set to 1:length(y)
%
% filters data using a running polynomial fit
%
% x: independent variable
% y: dependent variable
% fit_int: length of each fit
% fit_app_int: interval over which each fit is extrapolated (> fit_int)
% start_int: interval between consecutive fits (should be <= fit_int/2)
% q: quantile

if nargin == 5
    y = varargin{1};
    fit_int = varargin{2};
    fit_app_int = varargin{3};
    start_int = varargin{4};
    q = varargin{5};
    x = (1:length(y))';
elseif nargin == 6
    x = varargin{1};
    y = varargin{2};
    fit_int = varargin{3};
    fit_app_int = varargin{4};
    start_int = varargin{5};
    q = varargin{6};
end

if size(y,1) < size(y,2)
    y = y';
end
if size(x,1) < size(x,2)
    x = x';
end
%%
% x = yy; y = xx; fit_int = 10; fit_app_int = 10; start_int = 1; p_order = 2;


fitstarts = min(x)-start_int:start_int:max(x)-fit_int+start_int;
ncols = 20;
fit_matrix = nan(length(x),ncols);
%
if ~isempty(fitstarts)
inrange = x >= fitstarts(1) & x < fitstarts(end) + fit_int;

thiscol = 1;
earliest_col = 1;
last_x(thiscol) = min(x);

% figure;hold on
% plot(x,y)
slope_xs = nan(size(fitstarts));
slopes = nan(size(fitstarts));
slope_ys = nan(size(fitstarts));
%%
for fit_ix = 1:length(fitstarts)
    % find window for creating fit
    g = (x >= fitstarts(fit_ix)) & (x < fitstarts(fit_ix) + fit_int) & ~isnan(y);
    if sum(g)>3
        fit_center = fitstarts(fit_ix) + fit_int/2;
        %     find window for applying fit
        g_app = x >= fit_center - fit_app_int / 2 & ...
            x < fit_center + fit_app_int / 2 & inrange;
        x_segment = x(g);
        y_segment = y(g);
        b = regress(y_segment,[ones(size(y_segment)) x_segment]);
        b2 = mmqr(q,y_segment,[ones(size(y_segment)) x_segment],'xbeta',0.01,b);
        slope_xs(fit_ix) = (min(x_segment)+max(x_segment))/2;
        slopes(fit_ix) = b2(2);
        slope_ys(fit_ix) = b2(1) + b2(2)*slope_xs(fit_ix);
        
        x1 = x(g_app);
        y1 = b2(1) + b2(2)*x1;
        
        first_x = min(x1);
        if first_x > last_x(1)
            if thiscol ~= 1
                thiscol = 1;
                earliest_col = thiscol+1;
            end
        elseif first_x > last_x(earliest_col)
            thiscol = earliest_col;
            earliest_col = thiscol+1;
            if earliest_col > length(last_x)
                earliest_col = 1;
            end
        end
        fit_matrix(g_app,thiscol) = y1;
        if thiscol > ncols
            fit_matrix(~g_app,thiscol) = nan;
            ncols = ncols + 1;
        end
        
        last_x(thiscol) = max(x1);
        thiscol = thiscol + 1;
    end
    %     plot(x1,y1,'m')
end
%%
yfit = nanmedian(fit_matrix,2);
else
    yfit = nan;
    slope_xs = nan;
    slopes = nan;
end

% plot(x,yfit,'c')
