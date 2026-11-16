% GLOBESINK_netcdf_file_creation.m

clear;

dataset_name = 'GLOBESINK_global_2025_deep_aligned'; % Name of the file
    datafile_suffix = 'beta20260401_fluxes';
    % datafile_suffix = 'beta20260211_fluxes';
    % datafile_suffix = 'beta20250611_fluxes_interpolated';

datafile_name = ['BGC_Argo_monthly_maps_' dataset_name];

download_home = home_folder; % Home folder path
[BGC_Argo_data_folder,BGC_Argo_plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home); % Function to get folders

load([GLOBESINK_data_folder datafile_name '_' datafile_suffix '.mat']) 
load([GLOBESINK_data_folder datafile_name '_' datafile_suffix '_interpolated.mat']) 

cd([GLOBESINK_data_folder 'netcdf/'])

coords.depth = midpoints(zbin_edges)';   % 26 x 1
coords.lat      = midpoints(lat_edges)';        % 45 x 1
coords.lon      = midpoints(lon_edges)';        % 45 x 1
coords.month    = (1:12)';            % 12 x 1

meta.title = 'GLOBESINK monthly climatological maps';
meta.institution = 'National Oceanography Centre';
meta.source = 'Biogeochemical Argo';
meta.history = ['Created in MATLAB on ' datestr(now, 31)];
% meta.references = 'Insert dataset DOI or manuscript reference here';
% meta.comment = 'Variables mapped from GLOBESINK_netcdf_variable_details.xlsx';
meta.depth_units = 'm';

%% raw (non-interpolated product
GLOBESINK_export_monthly_maps_with_lookup(monthly_maps,'GLOBESINK_netcdf_variable_details.xlsx', ...
    'GLOBESINK_monthly_climatologies.nc',coords,meta);
GLOBESINK_append_flux_metadata_to_netcdf('GLOBESINK_monthly_climatologies.nc', flux_metadata);
GLOBESINK_add_uncertainty_bounds_to_netcdf(monthly_maps, ...
    'GLOBESINK_netcdf_variable_details.xlsx','GLOBESINK_monthly_climatologies.nc');
%% interpolated product
GLOBESINK_export_monthly_maps_with_lookup(monthly_maps_interpolated,'GLOBESINK_netcdf_variable_details.xlsx', ...
    'GLOBESINK_monthly_climatologies_smoothed_interpolated.nc',coords,meta);
GLOBESINK_append_flux_metadata_to_netcdf('GLOBESINK_monthly_climatologies_smoothed_interpolated.nc', flux_metadata);
% GLOBESINK_add_uncertainty_bounds_to_netcdf(monthly_maps_interpolated, ...
%     'GLOBESINK_netcdf_variable_details.xlsx','GLOBESINK_monthly_maps_interpolated.nc');
%% excel variable summary
GLOBESINK_generate_variable_summary_from_netcdf( ...
    'GLOBESINK_monthly_climatologies.nc', ...
    'GLOBESINK_netcdf_variable_summary.xlsx');
%%
tmp = ncinfo('GLOBESINK_monthly_climatologies.nc');
tmp2 = ncinfo('GLOBESINK_monthly_climatologies_smoothed_interpolated.nc');