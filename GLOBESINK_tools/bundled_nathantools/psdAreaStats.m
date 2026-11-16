function [area_mean, area_var] = psdAreaStats(D1, D2, b, Nexp, V)
% psdAreaStats  Mean & variance of area concentration for power‑law PSD.
%               Accepts scalars or arrays via implicit expansion.
%               Warns if D1≤0 or Nexp<0.

    % Sanity checks ------------------------------------------------------
    if any(D1(:) <= 0)
        warning('psdAreaStats:DminNonPositive', ...
            'D1 (Dmin) contains zero or negative values; results may be invalid.');
    end
    if any(Nexp(:) < 0)
        warning('psdAreaStats:NegativeNexp', ...
            'Nexp contains negative values; mean/variance may be non‑physical.');
    end

    % Core calculations --------------------------------------------------
    k = pi/4;
    denom = D2.^(1-b) - D1.^(1-b);          % <0 for b>1, D1>0
    muA  = k .* (1-b)./(3-b) .* (D2.^(3-b) - D1.^(3-b)) ./ denom;
    EA2  = k.^2 .* (1-b)./(5-b) .* (D2.^(5-b) - D1.^(5-b)) ./ denom;

    % area_mean = (Nexp ./ V)   .* muA;                       % [length unit]²/[volume unit]
    % area_var  = (Nexp ./ V.^2).* EA2 - (Nexp.^2 ./ V.^2) .* muA.^2; % [length unit]⁴/[volume unit]²
    area_mean = (Nexp ./ V)   .* muA;              % μ_A / V
    area_var  = (Nexp ./ V.^2).* EA2;              % Poisson variance
end

% 
% function [area_mean, area_var] = psdAreaStats(D1, D2, b, Nexp, V)
% % psdAreaStats  Mean and variance of area concentration.
% % Works for scalar, vector, or ND-array inputs using implicit expansion.
% % Any element where Nexp<=0 returns 0 mean/variance.
% 
%     % Element‑wise implicit expansion handles all size combos.
%     k = pi/4;
%     denom = D2.^(1-b) - D1.^(1-b);          % <0 for b>1
%     muA   = k .* (1-b)./(3-b) .* (D2.^(3-b) - D1.^(3-b)) ./ denom;
%     EA2   = k.^2 .* (1-b)./(5-b) .* (D2.^(5-b) - D1.^(5-b)) ./ denom;
% 
%     area_mean = (Nexp ./ V)   .* muA;
%     area_var  = (Nexp ./ V.^2).* EA2 - (Nexp.^2 ./ V.^2) .* muA.^2;
% 
%     % Issue warning for unphysical negative expected counts
%     if any(Nexp(:) < 0)
%         warning('psdAreaStats:NegativeNexp', ...
%                 'Nexp contains negative values; mean/variance may be non‑physical.');
%     end
% 
%     % area_mean(Nexp<=0) = 0;
%     % area_var(Nexp<=0) = 0;
% end
