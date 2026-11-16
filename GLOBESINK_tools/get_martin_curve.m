function [cf_,gof] = get_martin_curve(x,z)
% [cf_] = get_martin_curve(x,z)
% calculates and plots a Martin curve ? a power law law fit of the form
% flux(z) = a * (z/100)^-b where a = flux at 100 m and b is the magnitude
% of attenuation of flux. Displays b exponent and confidence interval on
% plot
%
% INPUT:    x = flux data
%           z = depth
%
% OUTPUT: cf_ = curve fit function. (cf_.a = a, cf_.b = b);
%
% by Nathan Briggs - natbrig@noc.ac.uk
% last modified 13 Nov 2024

g = ~isnan(x) & ~isnan(z);
if sum(g)>1
    x = x(g);z = z(g);
    [cf_,gof] = glider_martin_curve2(z/100,x);
else
    cf_ = nan;
end
