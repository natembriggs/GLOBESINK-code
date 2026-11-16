function [mu_pool, ci_lo_pool, ci_hi_pool] = poolMeansIVW(mu, ci_lo, ci_hi, alpha, dim)
% poolMeansIVW  Combine multiple means with inverse-variance weighting.
% -----------------------------------------------------------------------
% [MU_POOL, CI_LO_POOL, CI_HI_POOL] = poolMeansIVW(MU, CI_LO, CI_HI)
% [MU_POOL, CI_LO_POOL, CI_HI_POOL] = poolMeansIVW(MU, CI_LO, CI_HI, ALPHA)
% [MU_POOL, CI_LO_POOL, CI_HI_POOL] = poolMeansIVW(MU, CI_LO, CI_HI, ALPHA, DIM)
%
%   MU          : array of point estimates (means)
%   CI_LO       : same size as MU – lower bound of the confidence interval
%   CI_HI       : same size as MU – upper bound of the confidence interval
%   ALPHA       : two-sided significance level of the individual CIs
%                 (scalar, default 0.05 → 95 % intervals)
%   DIM         : (optional) dimension along which to pool.
%                 If omitted or empty, defaults to the first non-singleton
%                 dimension of MU (like MATLAB's mean).
%
% Returns
%   MU_POOL     : pooled mean (inverse-variance weighted),
%                 same size as MU, but size(MU_POOL,DIM) = 1.
%   CI_LO_POOL  : pooled lower confidence interval bound,
%                 same size as MU_POOL.
%   CI_HI_POOL  : pooled upper confidence interval bound,
%                 same size as MU_POOL.
% -----------------------------------------------------------------------
% Notes
% * Each mean is treated as Normal with variance derived from its CI.
% * Any element with NaN in MU or in its CI is ignored.
% * Implements fixed-effects meta-analysis (no between-study variance).
% -----------------------------------------------------------------------

    % defaults -----------------------------------------------------------
    if nargin < 4 || isempty(alpha)
        alpha = 0.05;           % default 95 % CI
    end

    % sanity checks on sizes/alpha --------------------------------------
    if ~isequal(size(mu), size(ci_lo), size(ci_hi))
        error('MU, CI_LO and CI_HI must have the same size.');
    end
    if ~isscalar(alpha) || alpha<=0 || alpha>=1
        error('ALPHA must be a scalar in (0,1).');
    end

    % default DIM like MATLAB mean: first non-singleton dimension --------
    if nargin < 5 || isempty(dim)
        sz = size(mu);
        dim = find(sz ~= 1, 1, 'first');
        if isempty(dim)
            dim = 1;   % all singleton → treat as dimension 1
        end
    end

    % validate DIM ------------------------------------------------------
    if ~isscalar(dim) || dim <= 0 || dim ~= floor(dim)
        error('DIM must be a positive integer scalar.');
    end

    % Ensure we account for dimensions beyond current ndims if needed ----
    nDims = max(ndims(mu), dim);

    % Permute so that DIM becomes the first dimension --------------------
    perm = [dim, setdiff(1:nDims, dim, 'stable')];
    mu_p    = permute(mu,    perm);
    lo_p    = permute(ci_lo, perm);
    hi_p    = permute(ci_hi, perm);

    sz_p    = size(mu_p);
    nAlong  = sz_p(1);          % length along DIM
    sz_rest = sz_p(2:end);      % remaining dims
    nRest   = prod(sz_rest);

    % Reshape to (nAlong × nRest) to process each "column" ---------------
    mu_2d = reshape(mu_p, [nAlong, nRest]);
    lo_2d = reshape(lo_p, [nAlong, nRest]);
    hi_2d = reshape(hi_p, [nAlong, nRest]);

    % Output holders (collapsed along DIM → 1 value per column) ----------
    mu_pool_vec  = NaN(1, nRest);
    ci_lo_vec    = NaN(1, nRest);
    ci_hi_vec    = NaN(1, nRest);

    z = norminv(1 - alpha/2);

    for j = 1:nRest
        mu_col = mu_2d(:, j);
        lo_col = lo_2d(:, j);
        hi_col = hi_2d(:, j);

        % discard NaNs for this column ----------------------------------
        valid = ~(isnan(mu_col) | isnan(lo_col) | isnan(hi_col));
        mu_v  = mu_col(valid);
        lo_v  = lo_col(valid);
        hi_v  = hi_col(valid);

        if isempty(mu_v)
            % leave NaNs for this position
            continue;
        end

        % convert CI to standard error for this column -------------------
        se   = (hi_v - lo_v) ./ (2*z);
        w    = 1 ./ se.^2;

        % pooled mean for this column -----------------------------------
        mu_pool_vec(j) = sum(w .* mu_v) / sum(w);

        % pooled SE and CI ----------------------------------------------
        se_pool        = sqrt(1 / sum(w));
        half_ci        = z * se_pool;
        ci_lo_vec(j)   = mu_pool_vec(j) - half_ci;
        ci_hi_vec(j)   = mu_pool_vec(j) + half_ci;
    end

    % Reshape back but keep DIM as size 1 (like mean) -------------------
    if isempty(sz_rest)
        % original array was effectively 1D along DIM
        out_sz = [1 1];    % for consistency, ipermute will fix it
    else
        out_sz = [1 sz_rest];
    end

    mu_pool_p    = reshape(mu_pool_vec, out_sz);
    ci_lo_pool_p = reshape(ci_lo_vec,   out_sz);
    ci_hi_pool_p = reshape(ci_hi_vec,   out_sz);

    % Inverse permute to original dimension order -----------------------
    mu_pool    = ipermute(mu_pool_p,    perm);
    ci_lo_pool = ipermute(ci_lo_pool_p, perm);
    ci_hi_pool = ipermute(ci_hi_pool_p, perm);

    % Make sure trailing singleton dimensions don't get dropped ----------
    % (ipermute can reduce ndims; we want at least nDims)
    sz_mu = size(mu);
    sz_out = size(mu_pool);
    if numel(sz_out) < numel(sz_mu)
        sz_out = [sz_out, ones(1, numel(sz_mu) - numel(sz_out))];
        mu_pool    = reshape(mu_pool,    sz_out);
        ci_lo_pool = reshape(ci_lo_pool, sz_out);
        ci_hi_pool = reshape(ci_hi_pool, sz_out);
    end
end
