% GLOBESINK_check_release_setup.m
%
% Quick check that the configuration, the bundled bathymetry loader and the
% CF/ACDD metadata export step work on this machine. Run it from anywhere,
% with the repository on the path: addpath(genpath('<repo>')).
%
% The metadata step is run on the published v1.0 files (the input of the v1.1
% upgrade, and the same structure as a fresh MATLAB export), writing into a
% temporary folder that is deleted afterwards. Nothing else is written.

fprintf('home_folder:      %s  (%s)\n', home_folder, which('home_folder'));
fprintf('argo_raw_folder:  %s  (%s)\n', argo_raw_folder, which('argo_raw_folder'));
assert(exist(home_folder, 'dir') == 7, 'home_folder does not exist');
assert(exist(argo_raw_folder, 'dir') == 7, 'argo_raw_folder does not exist');

b = load_global_bathymetry([50 51], [-5 -4], 1);
fprintf('bathymetry:       %d x %d points, %d to %d m\n', size(b.z), min(b.z(:)), max(b.z(:)));

python = GLOBESINK_config_field('python');
[status, msg] = system(sprintf('"%s" -c "import numpy, netCDF4, pandas, openpyxl; print(netCDF4.__version__)"', python));
assert(status == 0, 'Python is missing a package: %s', msg);
fprintf('python:           %s (netCDF4 %s)\n', python, strtrim(msg));

[~, ~, GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(home_folder);
v10 = [GLOBESINK_data_folder 'netcdf/GLOBESINK_Zenodo_submission_May2026/'];
tmp = tempname;
release = struct('product_version', 'check', 'coverage_end', '2025-05-31', ...
    'allow_placeholders', true);
GLOBESINK_apply_cf_acdd_metadata(v10, tmp, release);
info = ncinfo(fullfile(tmp, 'GLOBESINK_monthly_climatologies.nc'));
fprintf('metadata step:    wrote %d variables; Conventions = %s\n', numel(info.Variables), ...
    ncreadatt(fullfile(tmp, 'GLOBESINK_monthly_climatologies.nc'), '/', 'Conventions'));
rmdir(tmp, 's');
fprintf('All checks passed.\n');
