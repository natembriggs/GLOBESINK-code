function bath_struct = load_global_bathymetry(varargin)
% bath_struct = load_global_bathymetry(lat_limits,lon_limits,subsample_int);
%
% Loads the GEBCO One Minute Grid, version 2.0 (November 2008), from the 1-D
% GMT netCDF file GRIDONE_1D.nc, cropped to lat_limits and lon_limits and
% subsampled every subsample_int points. With no arguments, returns the whole
% globe subsampled every 20 points (1/3 degree).
%
% The file is located by cfg.gebco_file in GLOBESINK_config.m; if that is not
% set, GRIDONE_1D.nc must be on the MATLAB path. The grid is not redistributed
% here; see README section 5 for where to obtain it and its terms of use.
%
% Output fields: x (longitude, degrees east), y (latitude, degrees north,
% descending), z (elevation, m, negative below sea level), plus the raw GMT
% header variables.

if nargin<3
    subsample_int = 1;
else
    subsample_int = varargin{3};
end
if ~isempty(varargin)
    lat_limits = varargin{1};
    lon_limits = varargin{2};
else
    lat_limits = [-90 90];
    lon_limits = [-180 180];
    subsample_int = 20;
end

gebco_file = 'GRIDONE_1D.nc';
if exist('GLOBESINK_config', 'file') == 2
    cfg = GLOBESINK_config();
    if isfield(cfg, 'gebco_file') && ~isempty(cfg.gebco_file)
        gebco_file = cfg.gebco_file;
    end
end
if ~exist(gebco_file, 'file')
    error('GLOBESINK:bathymetry', ['GEBCO grid not found (%s). Set cfg.gebco_file ' ...
        'in GLOBESINK_config.m; see README section 5.'], gebco_file);
end

tmp = ncinfo(gebco_file);
for vix = 1:length(tmp.Variables)
    bath_struct.(tmp.Variables(vix).Name) = ncread(gebco_file,tmp.Variables(vix).Name);
end

bath_struct.x = bath_struct.x_range(1):bath_struct.spacing(1):bath_struct.x_range(2);
bath_struct.y = (bath_struct.y_range(2):-bath_struct.spacing(2):bath_struct.y_range(1))';
bath_struct.z = reshape(bath_struct.z,length(bath_struct.x),[])';

gx = is_between(bath_struct.x,lon_limits);
gy = is_between(bath_struct.y,lat_limits);

bath_struct.x = bath_struct.x(gx);
bath_struct.y = bath_struct.y(gy);
bath_struct.z = bath_struct.z(gy,gx);

bath_struct.x = bath_struct.x(1:subsample_int:end);
bath_struct.y = bath_struct.y(1:subsample_int:end);
bath_struct.z = bath_struct.z(1:subsample_int:end,1:subsample_int:end);
