function GLOBESINK_export_monthly_maps_with_lookup(monthly_maps, excel_file, ncfile, coords, meta)
% GLOBESINK_export_monthly_maps_with_lookup(monthly_maps, excel_file, ncfile, coords, meta)
%
% Export monthly_maps.variable_type.variable_name to NetCDF using a lookup
% table stored in an Excel spreadsheet.
%
% Required spreadsheet columns:
%   variable_type
%   variable_name
%   netcdf_name
%   units
%   variable_description
%
% Example struct access:
%   monthly_maps.baseline2_refractory.BBP700
%
% Expected variable size:
%   [depth, lat, lon, month]
%
% Inputs
%   monthly_maps : MATLAB struct
%   excel_file   : e.g. 'GLOBESINK_netcdf_variable_details.xlsx'
%   ncfile       : e.g. 'GLOBESINK_monthly_maps.nc'
%   coords       : struct with fields:
%                    .depth  (26x1)
%                    .lat       (45x1)
%                    .lon       (45x1)
%                    .month     (12x1, usually 1:12)
%   meta         : optional struct of global metadata, e.g.
%                    .title
%                    .institution
%                    .source
%                    .history
%                    .references
%                    .comment
%                    .depth_units   (default 'm')
%
% Notes
% - All mapped variables are written as single precision.
% - NaNs are replaced with FillValue.
% - Variables missing from monthly_maps are skipped with a warning.

if nargin < 5
    meta = struct();
end

fillValue = single(-9999);

% -------------------------------------------------------------------------
% Read lookup table
% -------------------------------------------------------------------------
T = readtable(excel_file, 'TextType', 'string');

requiredCols = ["variable_type", "variable_name", "netcdf_name", "units", "variable_description"];
missingCols = requiredCols(~ismember(requiredCols, string(T.Properties.VariableNames)));
if ~isempty(missingCols)
    error('Spreadsheet is missing required columns: %s', strjoin(cellstr(missingCols), ', '));
end

% Remove completely empty rows in the key columns
isEmptyKeyRow = strlength(strtrim(T.variable_type)) == 0 | ...
                strlength(strtrim(T.variable_name)) == 0 | ...
                strlength(strtrim(T.netcdf_name)) == 0;
T(isEmptyKeyRow, :) = [];

% -------------------------------------------------------------------------
% Check coordinates
% -------------------------------------------------------------------------
requiredCoordFields = {'depth', 'lat', 'lon', 'month'};
for i = 1:numel(requiredCoordFields)
    if ~isfield(coords, requiredCoordFields{i})
        error('coords.%s is required.', requiredCoordFields{i});
    end
end

nP = numel(coords.depth);
nY = numel(coords.lat);
nX = numel(coords.lon);
nM = numel(coords.month);

expectedSize = [nP, nY, nX, nM];

% -------------------------------------------------------------------------
% Overwrite existing NetCDF if present
% -------------------------------------------------------------------------
if exist(ncfile, 'file')
    delete(ncfile);
end

% -------------------------------------------------------------------------
% Create coordinate variables
% -------------------------------------------------------------------------
nccreate(ncfile, 'depth', ...
    'Dimensions', {'depth', nP}, ...
    'Datatype', 'single');
ncwrite(ncfile, 'depth', single(coords.depth(:)));
ncwriteatt(ncfile, 'depth', 'long_name', 'center of depth bin');
ncwriteatt(ncfile, 'depth', 'units', getfieldwithdefault(meta, 'depth_units', 'dbar'));
ncwriteatt(ncfile, 'depth', 'positive', 'down');
ncwriteatt(ncfile, 'depth', 'axis', 'Z');

nccreate(ncfile, 'lat', ...
    'Dimensions', {'lat', nY}, ...
    'Datatype', 'single');
ncwrite(ncfile, 'lat', single(coords.lat(:)));
ncwriteatt(ncfile, 'lat', 'long_name', 'center of latitude bin');
ncwriteatt(ncfile, 'lat', 'units', 'degrees_north');
ncwriteatt(ncfile, 'lat', 'axis', 'Y');

nccreate(ncfile, 'lon', ...
    'Dimensions', {'lon', nX}, ...
    'Datatype', 'single');
ncwrite(ncfile, 'lon', single(coords.lon(:)));
ncwriteatt(ncfile, 'lon', 'long_name', 'center of longitude bin');
ncwriteatt(ncfile, 'lon', 'units', 'degrees_east');
ncwriteatt(ncfile, 'lon', 'axis', 'X');

nccreate(ncfile, 'month', ...
    'Dimensions', {'month', nM}, ...
    'Datatype', 'int16');
ncwrite(ncfile, 'month', int16(coords.month(:)));
ncwriteatt(ncfile, 'month', 'long_name', 'climatological month');
ncwriteatt(ncfile, 'month', 'units', '1');
ncwriteatt(ncfile, 'month', 'comment', '1=January, 2=February, ..., 12=December');
ncwriteatt(ncfile, 'month', 'axis', 'T');

% -------------------------------------------------------------------------
% Global attributes
% -------------------------------------------------------------------------
ncwriteatt(ncfile, '/', 'Conventions', 'CF-1.8');
write_global_att(ncfile, meta, 'title');
write_global_att(ncfile, meta, 'institution');
write_global_att(ncfile, meta, 'source');
write_global_att(ncfile, meta, 'history');
write_global_att(ncfile, meta, 'references');
write_global_att(ncfile, meta, 'comment');

% Add provenance for lookup table
ncwriteatt(ncfile, '/', 'variable_lookup_table', excel_file);

% -------------------------------------------------------------------------
% Loop through spreadsheet rows and write variables
% -------------------------------------------------------------------------
nWritten = 0;
nSkipped = 0;

for iRow = 1:height(T)

    variableType = GLOBESINK_safe_table_string(T.variable_type(iRow));
    variableName = GLOBESINK_safe_table_string(T.variable_name(iRow));
    netcdfName   = GLOBESINK_safe_table_string(T.netcdf_name(iRow));
    unitsStr     = GLOBESINK_safe_table_string(T.units(iRow));
    descStr      = GLOBESINK_safe_table_string(T.variable_description(iRow));

    % Sanitize NetCDF variable name just in case
    netcdfName = regexprep(netcdfName, '[^A-Za-z0-9_]', '_');

    % Check structure path exists
    if ~isfield(monthly_maps, variableType)
        warning('Skipping row %d: monthly_maps.%s does not exist.', iRow, variableType);
        nSkipped = nSkipped + 1;
        continue
    end

    if ~isstruct(monthly_maps.(variableType))
        warning('Skipping row %d: monthly_maps.%s is not a struct.', iRow, variableType);
        nSkipped = nSkipped + 1;
        continue
    end

    if ~isfield(monthly_maps.(variableType), variableName)
        warning('Skipping row %d: monthly_maps.%s.%s does not exist.', iRow, variableType, variableName);
        nSkipped = nSkipped + 1;
        continue
    end

    data = monthly_maps.(variableType).(variableName);

    if ~isnumeric(data)
        warning('Skipping row %d: monthly_maps.%s.%s is not numeric.', iRow, variableType, variableName);
        nSkipped = nSkipped + 1;
        continue
    end

    % Enforce 4D size
    sz = size(data);
    if numel(sz) < 4
        sz(end+1:4) = 1;
    end

    if ~isequal(sz(1:4), expectedSize)
        warning(['Skipping row %d: monthly_maps.%s.%s has size [%s], expected [%s].'], ...
            iRow, variableType, variableName, num2str(sz(1:4)), num2str(expectedSize));
        nSkipped = nSkipped + 1;
        continue
    end

    % Create variable
    nccreate(ncfile, netcdfName, ...
        'Dimensions', {'depth', nP, 'lat', nY, 'lon', nX, 'month', nM}, ...
        'Datatype', 'single', ...
        'FillValue', fillValue);

    % Replace NaNs
    dataOut = single(data);
    dataOut(isnan(dataOut)) = fillValue;

    % Write data
    ncwrite(ncfile, netcdfName, dataOut);

    % Variable attributes
    ncwriteatt(ncfile, netcdfName, 'long_name', char(descStr));
    ncwriteatt(ncfile, netcdfName, 'coordinates', 'depth lat lon month');
    % ncwriteatt(ncfile, netcdfName, 'source_variable_type', char(variableType));
    ncwriteatt(ncfile, netcdfName, 'source_variable_name', char(variableName));

    if strlength(unitsStr) > 0
        ncwriteatt(ncfile, netcdfName, 'units', char(unitsStr));
    else
        ncwriteatt(ncfile, netcdfName, 'units', '1');
    end

    nWritten = nWritten + 1;
end

fprintf('Finished writing NetCDF file: %s\n', ncfile);
fprintf('Variables written: %d\n', nWritten);
fprintf('Variables skipped: %d\n', nSkipped);

end

% =========================================================================
% Helper functions
% =========================================================================
function write_global_att(ncfile, meta, fieldname)
if isfield(meta, fieldname)
    ncwriteatt(ncfile, '/', fieldname, meta.(fieldname));
end
end

function val = getfieldwithdefault(S, fieldname, defaultVal)
if isfield(S, fieldname)
    val = S.(fieldname);
else
    val = defaultVal;
end
end