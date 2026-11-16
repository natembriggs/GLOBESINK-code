function out_folder = GLOBESINK_apply_cf_acdd_metadata(src_folder, out_folder, release)
% out_folder = GLOBESINK_apply_cf_acdd_metadata(src_folder, out_folder, release);
%
% Final export step: applies the CF-1.8 and ACDD-1.3 metadata of the published
% dataset (v1.1 onwards) to the two NetCDF products written by
% GLOBESINK_export_monthly_maps_with_lookup, and writes the variable summary
% spreadsheet from the result. The metadata definitions live in one place,
% cf_acdd_metadata/GLOBESINK_cf_acdd_metadata.py, which also produced v1.1 from
% the published v1.0 files, so every later version carries the same metadata.
% Gridded values are copied unchanged and verified against the input files.
%
% Inputs
%   src_folder  folder holding GLOBESINK_monthly_climatologies.nc and
%               GLOBESINK_monthly_climatologies_smoothed_interpolated.nc
%   out_folder  folder to write the release files into (created if needed)
%   release     struct with fields
%                 .product_version  e.g. '2.0'
%                 .coverage_end     last day of observations, 'YYYY-MM-DD'
%               and optionally
%                 .dataset_doi      DOI of this version, once minted
%                 .paper_doi        DOI of the data paper
%                 .code_doi         Zenodo DOI of this code release
%                 .code_version     git tag or commit; default: git describe
%                 .allow_placeholders  true for a draft before the DOIs exist
%
% Requires a Python 3 with numpy, netCDF4 and pandas (with openpyxl), named by
% cfg.python in GLOBESINK_config.m.

script = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
    'cf_acdd_metadata', 'GLOBESINK_cf_acdd_metadata.py');
python = GLOBESINK_config_field('python');

if ~isfield(release, 'code_version') || isempty(release.code_version)
    repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    [status, described] = system(sprintf('git -C "%s" describe --tags --always --dirty', repo));
    if status ~= 0
        error('GLOBESINK:metadata', 'Could not read the code version with git: %s', described);
    end
    release.code_version = strtrim(described);
end

args = sprintf(['"%s" "%s" --mode export --src "%s" --out "%s" --product-version "%s" ' ...
    '--coverage-end "%s" --code-version "%s" --compress --mask-nonfinite'], ...
    python, script, src_folder, out_folder, release.product_version, ...
    release.coverage_end, release.code_version);
optional = {'dataset_doi', '--dataset-doi'; 'paper_doi', '--paper-doi'; 'code_doi', '--code-doi'};
for i = 1:size(optional, 1)
    if isfield(release, optional{i,1}) && ~isempty(release.(optional{i,1}))
        args = sprintf('%s %s "%s"', args, optional{i,2}, release.(optional{i,1}));
    end
end
if isfield(release, 'allow_placeholders') && release.allow_placeholders
    args = [args ' --allow-placeholders'];
end

fprintf('Applying CF/ACDD metadata:\n  %s\n', args);
status = system(args);
if status ~= 0
    error('GLOBESINK:metadata', ['GLOBESINK_cf_acdd_metadata.py failed (exit %d); ' ...
        'see the messages above. Nothing in %s should be used.'], status, out_folder);
end
