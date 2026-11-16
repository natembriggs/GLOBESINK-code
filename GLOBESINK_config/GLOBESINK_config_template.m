function cfg = GLOBESINK_config()
% cfg = GLOBESINK_config();
%
% Machine-specific paths for the GLOBESINK pipeline. TEMPLATE: copy this file
% to GLOBESINK_config.m in the same folder and edit the paths there. The copy
% is ignored by git, so your paths are never committed.
%
%   cfg.home_folder      Root folder holding BiogeochemicalArgo/{data,plots}/.
%                        GLOBESINK's .mat outputs, NetCDF products and plots go
%                        under it (see get_BGC_Argo_data_and_plot_folders).
%   cfg.argo_raw_folder  Root of a local mirror of the Argo GDAC, with the GDAC
%                        layout: dac/<dac>/<wmo>/..., aux/<dac>/<wmo>/...,
%                        index/*.txt. All raw Argo reads and downloads go here.
%   cfg.gebco_file       Full path to the GEBCO One Minute Grid, version 2.0
%                        (November 2008), in the 1-D GMT netCDF format
%                        (GRIDONE_1D.nc, about 470 MB). Used by
%                        load_global_bathymetry for shelf masking and cast
%                        bathymetry. See README section 5.
%   cfg.python           Python 3 executable with numpy, netCDF4, pandas and
%                        openpyxl, used by the final export step to apply the
%                        CF/ACDD metadata (GLOBESINK_apply_cf_acdd_metadata).
%
% Folder paths should end with a file separator ('/' or '\').

cfg.home_folder = '/path/to/your/Matlab/';
cfg.argo_raw_folder = '/path/to/your/Argo/';
cfg.gebco_file = '/path/to/GRIDONE_1D.nc';
cfg.python = 'python3';
