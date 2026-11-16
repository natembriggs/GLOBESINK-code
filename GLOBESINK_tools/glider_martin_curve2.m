function [cf_,gof] = glider_martin_curve2(cf_x,cf_y)
%   glider_martin_curve    Create plot of datasets and fits
%   glider_martin_curve(CF_X,CF_Y)
%   cf_x: depth data (z/100m)
%   cf_y: optics data
%   Creates a plot, similar to the plot in the main curve fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with cftool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  1
%   Number of fits:  1


% Data from dataset "cf_y vs. cf_x":
%    X = cf_x:
%    Y = cf_y:
%    Unweighted
%
% This function was automatically generated on 18-Jun-2010 11:45:06

% Set up figure to receive datasets and fits
% f_ = clf;
% figure(f_);
% set(f_,'Units','Pixels','Position',[574 256 680 481]);
% legh_ = []; legt_ = {};   % handles and text for legend
% xlim_ = [Inf -Inf];       % limits of x axis
% ax_ = axes;
% set(ax_,'Units','normalized','OuterPosition',[0 0 1 1]);
% set(ax_,'Box','on');
% axes(ax_); hold on;


% --- Plot data originally in dataset "cf_y vs. cf_x"
cf_x = cf_x(:);
cf_y = cf_y(:);
% h_ = line(cf_x,cf_y,'Parent',ax_,'Color',[0.333333 0 0.666667],...
%     'LineStyle','none', 'LineWidth',1,...
%     'Marker','.', 'MarkerSize',12);
% xlim_(1) = min(xlim_(1),min(cf_x));
% xlim_(2) = max(xlim_(2),max(cf_x));
% legh_(end+1) = h_;
% legt_{end+1} = 'cf_y vs. cf_x';

% % Nudge axis limits beyond data limits
% if all(isfinite(xlim_))
%     xlim_ = xlim_ + [-1 1] * 0.01 * diff(xlim_);
%     set(ax_,'XLim',xlim_)
% else
%     set(ax_, 'XLim',[1.1699999999999999, 9.3300000000000001]);
% end


% --- Create fit "fit 3"
ok_ = isfinite(cf_x) & isfinite(cf_y);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
% st_ = [max(cf_y(ok_)) -1];
ft_ = fittype( 'power1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
% opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.StartPoint = [max(cf_y(ok_)) -1];
opts.Lower = [0 -10];
opts.Upper = [Inf 1];
opts.TolFun = max(cf_y(ok_))*1e-6;
opts.TolX = max(cf_y(ok_))*1e-6;

% Fit this model using new data
[cf_,gof] = fit(cf_x(ok_),cf_y(ok_),ft_,opts);

% Or use coefficients from the original fit:
if 0
    cv_ = { 0.00029133719198512622, -0.63407751300637405};
    cf_ = cfit(ft_,cv_{:});
end

% Plot this fit
% h_ = plot(cf_,'fit',0.95);
% legend off;  % turn off legend from plot method call
% set(h_(1),'Color',[1 0 0],...
%     'LineStyle','-', 'LineWidth',2,...
%     'Marker','none', 'MarkerSize',6);
% legh_(end+1) = h_(1);
% legt_{end+1} = 'power law fit';

% Done plotting data and fits.  Now finish up loose ends.
% hold off;
% leginfo_ = {'Orientation', 'vertical', 'Location', 'NorthEast'};
% h_ = legend(ax_,legh_,legt_,leginfo_{:});  % create legend
% set(h_,'Interpreter','none');
% xlabel(ax_,'');               % remove x label
% ylabel(ax_,'');               % remove y label
