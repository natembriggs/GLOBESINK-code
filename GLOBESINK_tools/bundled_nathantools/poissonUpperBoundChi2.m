function [lambdaUp, Nmiss] = poissonUpperBoundChi2(k, alpha)
    if nargin<2, alpha=0.05; end
    lambdaUp = 0.5 * chi2inv(1-alpha, 2*(k+1));
    Nmiss    = lambdaUp - k;
end
