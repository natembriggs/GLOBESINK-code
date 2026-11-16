function [lambdaLo, NmissLo] = poissonLowerBoundChi2(k, alpha)
    if nargin<2, alpha=0.05; end
    % if k==0
    %     lambdaLo  = zeros(size(k)); NmissLo = 0;
    % else
        lambdaLo  = 0.5 * chi2inv(alpha, 2*k);
        NmissLo   = k - lambdaLo;   % over‑count
    % end
end
