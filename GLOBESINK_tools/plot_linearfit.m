function [h_l, h_t, m, b, mrange, brange, r2, p, RMSE] = plot_linearfit(varargin)
% [h_l, h_t, m, b, mrange, brange, r2, p, RMSE] = plot_linearfit(X,y,pm,pb,pr,pRMSE)
% Calls function lsqfitma.m to find type II linear fit line and plots the line along
% with its equation (with precisions pm and pb), r^2 value (precision pr),
% and root mean square error (precision pRMSE)
%
% OUTPUT VARIABLES
% h_l = line handle
% h_t = vector containing the three text handles
% m = regression slope 
% b = regression y offset 
% mrange = 95% conf. int. of slope
% brange = 95% conf. int. of offset
% r2 = regression r^2
% p = regression p value

g = ~isnan(varargin{1}) & ~isnan(varargin{2});
X = varargin{1}(g);
y = varargin{2}(g);

pm = 3;
pb = 3;
pr = 2;
pRMSE = 3;
switch nargin
    case 3
        pm = varargin{3};
        pb = varargin{3};
    case 4
        pm = varargin{3};
        pb = varargin(4);
    case 5
        pm = varargin{3};
        pb = varargin{4};
        pr = varargin{5};
    case 6
        pm = varargin{3};
        pb = varargin{4};
        pr = varargin{5};
        pRMSE = varargin{6};
end
    

if size(X,1) < size(X,2)
    X = X';
end
if size(y,1) < size(y,2)
    y = y';
end

g = ~isnan(X) & ~isnan(y) & ~isinf(X) & ~isinf(y);
X = X(g); y = y(g);

[b, bint, ~, ~, stats] = regress(y,[ones(size(y)) X]);
x_new = [min(X) max(X)];
y_new = b(1) + b(2)*x_new;
h_l = plot(x_new,y_new,'k');
brange = b - bint(:,1);
mrange = brange(2);
brange = brange(1);
m = b(2);
b = b(1);
r2 = stats(1);
p = stats(3);
RMSE = sqrt(stats(4));
%% ELABORATE CODE TO FORCE EVERYTHING TO THE RIGHT DECIMAL
mlog = floor(log10(abs(m)));
mshift =  pm-mlog-1;
mround = 10^-mshift*(round(m*10^mshift));
newp = mshift*(mshift>0);
mstr = num2str(mround,['%.' num2str(newp) 'f']);

mrangeround = 10^-mshift*(round(mrange*10^mshift));
mrangestr = num2str(mrangeround,['%.' num2str(newp) 'f']);

blog = floor(log10(abs(b)));
bshift =  pb-blog-1;
bround = 10^-bshift*(round(b*10^bshift));
newp = bshift*(bshift>0);
if bround < 0
    plusminus = ' - ';
    bround = -bround;
else
    plusminus = ' + ';
end
bstr = num2str(bround,['%.' num2str(newp) 'f']);

brangeround = 10^-bshift*(round(brange*10^bshift));
brangestr = num2str(brangeround,['%.' num2str(newp) 'f']);
rstr = num2str(r2,['%.' num2str(pr) 'f']);
% RMSEstr = num2str(RMSE,['%.' num2str(pRMSE) 'f']);
RMSEstr = num2str(RMSE,pRMSE);

% PRINT EQUATION ON FIGURE
h_t(1) = text(0.05,0.95,['y = ' mstr '±' mrangestr ...
    'x' plusminus bstr '±' brangestr],'sc');
% h_t(1) = text(0.05,0.95,['m = ' mstr '±' mrangestr],'sc');
% PRINT R^2 ON FIGURE
h_t(2) = text(0.05,0.85,['r^2 = ' rstr],'sc');
% PRINT RMSE ON FIGURE
h_t(3) = text(0.3,0.85,['RMSE = ' RMSEstr],'sc');

% % PRINT P VALUE ON FIGURE
% h_t(3) = text(0.55,0.85,['p = ' num2str(stats(3),2)],'sc');

set(h_t,'fontsize',11)
set(h_l,'linewidth',2)
% b = [b m];

