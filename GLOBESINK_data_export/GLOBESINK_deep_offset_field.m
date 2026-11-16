function GLOBESINK_deep_offset_field(bins_file, offsets_xlsx, nbbp_nc, out_mat)
% GLOBESINK_deep_offset_field(bins_file, offsets_xlsx, nbbp_nc, out_mat)
%
% Gridded field of the deep-alignment offsets applied in a GLOBESINK product,
% added to dataset v1.1 so that users can see, and approximately undo, what
% the alignment did in each cell.
%
% For every cell (depth x lat x lon x month) it computes, exactly as
% GLOBESINK_monthly_climatology_maps grids the data:
%   mo   sample-weighted mean of the per-float additive offsets applied to the
%        floats contributing bbp measurements to the cell (m-1)
%   nfl  number of distinct floats contributing (any year)
%   sn   total number of bbp measurements (must equal the product's n_bbp)
%   sn_nooff  measurements from floats that were not aligned (no neighbour in range)
%
% bins_file     deep-aligned monthly per-float bins (monthly_bins, float_WMOs, t_edges)
% offsets_xlsx  the applied per-float offset table (WMO, offset)
% nbbp_nc       the product's raw climatology; n_bbp is used as an identity check
% out_mat       output .mat (v7) with mo, nfl, sn, sn_nooff
%
% For the published v1.0 (11 Nov 2026): bins
% BGC_Argo_monthly_bins_GLOBESINK_global_2025_deep_aligned_beta20260401.mat, offsets
% netcdf/GLOBESINK_Zenodo_corrections_Oct2026/GLOBESINK_BBP700_deep_offsets.xlsx; n_bbp was
% reproduced in all 607,500 cells.

B = load(bins_file, 'monthly_bins', 'float_WMOs', 't_edges');
mb = B.monthly_bins; wmo = B.float_WMOs;
T = readtable(offsets_xlsx);
[tf, loc] = ismember(wmo, T{:,1});
offf = zeros(numel(wmo), 1); offf(tf) = T{loc(tf), 2};
% Floats with no neighbour in range have a NaN offset in the table and were not
% aligned (their aligned and unaligned bins are identical): applied offset 0.
unaligned = isnan(offf); offf(unaligned) = 0; tf(unaligned) = false;
fprintf('%d floats in the bins with an applied offset, %d without (offset 0)\n', nnz(tf), nnz(~tf));
lat_edges = -90:4:90; lon_edges = -180:8:180;
[~, mm] = datevec(B.t_edges(1:end-1)');
nz = size(mb.nfilt.BBP700, 1);
sn = zeros(nz, 45, 45, 12); sno = sn; nfl = sn; sn_nooff = sn;
for mix = 1:12
    tm = mm == mix;
    n = mb.nfilt.BBP700(:, tm, :); v = mb.baseline2.BBP700(:, tm, :);
    bad = isnan(v + n) | isinf(v); n(bad) = 0;
    la = mb.LATITUDE(:, tm, :); lo = mb.LONGITUDE(:, tm, :);
    fo = repmat(reshape(offf, 1, 1, []), 1, nnz(tm), 1);
    hasoff = repmat(reshape(tf, 1, 1, []), 1, nnz(tm), 1);
    fidall = repmat(reshape(1:numel(wmo), 1, 1, []), 1, nnz(tm), 1);
    for latix = 1:45
        glat = la >= lat_edges(latix) & la <= lat_edges(latix + 1);
        if ~any(glat(:)), continue, end
        for lonix = 1:45
            g = glat & lo >= lon_edges(lonix) & lo <= lon_edges(lonix + 1);
            if ~any(g(:)), continue, end
            g2 = reshape(g, 1, []);
            nn = reshape(n, nz, []); nn = nn(:, g2);
            ff = reshape(fo, 1, []); ff = ff(g2);
            ho = reshape(hasoff, 1, []); ho = ho(g2);
            fid = reshape(fidall, 1, []); fid = fid(g2);
            sn(:, latix, lonix, mix) = sum(nn, 2);
            sno(:, latix, lonix, mix) = nn * ff';
            sn_nooff(:, latix, lonix, mix) = nn * double(~ho)';
            for z = 1:nz
                nfl(z, latix, lonix, mix) = numel(unique(fid(nn(z, :) > 0)));
            end
        end
    end
end
nb = ncread(nbbp_nc, 'n_bbp'); nb(nb == -9999) = 0;
if any(nb(:) ~= sn(:))
    error('GLOBESINK:offsets', 'n_bbp not reproduced in %d cells: wrong bins file?', nnz(nb(:) ~= sn(:)));
end
mo = sno ./ sn; mo(sn == 0) = NaN;
save(out_mat, 'mo', 'nfl', 'sn', 'sn_nooff', '-v7');
fprintf('n_bbp reproduced in all cells; %d cells with an offset; wrote %s\n', nnz(~isnan(mo)), out_mat);
