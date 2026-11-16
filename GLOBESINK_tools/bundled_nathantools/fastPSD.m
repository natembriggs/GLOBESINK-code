function [bHat, se_b, ci_b] = fastPSD(D, Dmin, alpha)
% [bHat, se_b, ci_b] = fastPSD(D, Dmin, alpha);
%
% estimates particle size distribution slope bHat from individual particle
% diameter measurements D with Dmin as lower bound and no upper bound. se_b
% is standard error of PSD slope, and ci_b is confidence interval at
% significance threshold alpha (0.05 for 95% CI)
    if nargin < 3, alpha = 0.05; end
    D = D(D>=Dmin);
    n    = numel(D);
    bHat = 1 + n / sum( log(D./Dmin) );
    se_b = (bHat - 1)/sqrt(n);
    z    = norminv(1 - alpha/2);
    ci_b = bHat + z*[-1 1]*se_b;
end
