function [h_l, h_t, cf_,gof] = plot_martin_curve(x,z)
% [h_l h_t cf_] = plot_martin_curve(x,z)
% calculates and plots a Martin curve ? a power law law fit of the form
% flux(z) = a * (z/100)^-b where a = flux at 100 m and b is the magnitude
% of attenuation of flux. Displays b exponent and confidence interval on
% plot
%
% INPUT:    x = flux data
%           z = depth
%
% OUTPUT: cf_ = curve fit function. (cf_.a = a, cf_.b = b);
%         h_l = handle for curve fit line
%         h_t = handle for text displaying b exponent
%
% by Nathan Briggs - nathan.m.briggs@maine.edu
% last modified 18 Dec 2010

g = ~isnan(x) & ~isnan(z);
if sum(g)>1
    x = x(g);z = z(g);
    [cf_,gof] = glider_martin_curve2(z/100,x);
    mlims = [min(z) max(z)];
    h_l = plot(cf_((mlims(1):5:mlims(2))/100),(mlims(1):5:mlims(2)),...
        'k','linewidth',2);
    % plot(cf_.a*((mlims(1):5:mlims(2))/100).^cf_.b,(mlims(1):5:mlims(2)),...
    %     'k','linewidth',2)
    % plot(cf_.a*((100:5:mlims(2))/100).^cf_.b,(100:5:mlims(2)),...
    %     '--k','linewidth',2)
    if sum(g)>2
        b_conf = confint(cf_);
        bint = abs(diff(b_conf(:,2))/2);
    else
        bint = nan;
    end
    
    sst = sum((x - mean(x)).^2);
    ssr = sum((cf_(z/100) - x).^2);
    r2 = (sst-ssr)/sst;
    
    % h_t = text(0.95,0.2,['x = ' num2str(cf_.a,3) '(y/100)^{-' ...
    %     num2str(-cf_.b,2) '±' num2str(bint,2) '}'],'sc');
    h_t = text(0.95,0.2,['x = ' num2str(cf_.a,3) '(y/100)^{' ...
        num2str(cf_.b,2) '±' num2str(bint,2) '}'],'sc');
    h_t(2) = text(0.95,0.1,['r^2 = ' num2str(r2,3)],'sc');
    set(h_t,'horizontalalignment','right','fontsize',16)
else
    h_l = nan; h_t = nan; cf_ = nan;
end
