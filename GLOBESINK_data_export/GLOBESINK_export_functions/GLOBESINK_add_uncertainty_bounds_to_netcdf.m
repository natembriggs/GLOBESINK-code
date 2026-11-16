function GLOBESINK_add_uncertainty_bounds_to_netcdf(monthly_maps, excel_file, ncfile)
% GLOBESINK_add_uncertainty_bounds_to_netcdf(monthly_maps, excel_file, ncfile)
%
% Append additive upper/lower uncertainty fields from monthly_maps to an
% existing NetCDF file, using the same spreadsheet lookup used for the main
% variables.
%
% Searches for:
%   monthly_maps.uncertainties.<variable_type>.<variable_name>.upper.precision
%   monthly_maps.uncertainties.<variable_type>.<variable_name>.lower.precision
%   monthly_maps.uncertainties.<variable_type>.<variable_name>.upper.total_systematic
%   monthly_maps.uncertainties.<variable_type>.<variable_name>.lower.total_systematic
%
% Only these two uncertainty types are written:
%   - precision
%   - total_systematic
%
% Output variable naming:
%   <netcdf_name>_precision_upper
%   <netcdf_name>_precision_lower
%   <netcdf_name>_systematic_uncertainty_upper
%   <netcdf_name>_systematic_uncertainty_lower
%
% Units:
%   same as the parent variable
%
% long_name:
%   precision:
%       'upper 95% confidence bound for precision uncertainty of ...'
%       'lower 95% confidence bound for precision uncertainty of ...'
%   systematic:
%       'upper additive systematic uncertainty propagated from upper and lower bounds of parameter values used in this dataset for ...'
%       'lower additive systematic uncertainty propagated from upper and lower bounds of parameter values used in this dataset for ...'
%
% Example:
%   GLOBESINK_add_uncertainty_bounds_to_netcdf( ...
%       monthly_maps, ...
%       'GLOBESINK_netcdf_variable_details.xlsx', ...
%       'GLOBESINK_monthly_maps.nc');

if ~exist(ncfile, 'file')
    error('NetCDF file does not exist: %s', ncfile);
end

% -------------------------------------------------------------------------
% Read lookup table
% -------------------------------------------------------------------------
T = readtable(excel_file, 'TextType', 'string');

requiredCols = ["variable_type", "variable_name", "netcdf_name", "units", "variable_description"];
missingCols = requiredCols(~ismember(requiredCols, string(T.Properties.VariableNames)));
if ~isempty(missingCols)
    error('Spreadsheet is missing required columns: %s', strjoin(cellstr(missingCols), ', '));
end

% remove empty key rows
isEmptyKeyRow = strlength(strtrim(T.variable_type)) == 0 | ...
                strlength(strtrim(T.variable_name)) == 0 | ...
                strlength(strtrim(T.netcdf_name)) == 0;
T(isEmptyKeyRow, :) = [];

% -------------------------------------------------------------------------
% Determine expected data dimensions from existing NetCDF coordinate vars
% -------------------------------------------------------------------------
info = ncinfo(ncfile);

nP = GLOBESINK_get_dim_length(info, 'depth');
nY = GLOBESINK_get_dim_length(info, 'lat');
nX = GLOBESINK_get_dim_length(info, 'lon');
nM = GLOBESINK_get_dim_length(info, 'month');

expectedSize = [nP, nY, nX, nM];
fillValue = single(-9999);

% uncertainty types to export
uncTypes = {'precision', 'total_systematic'};

nWritten = 0;
nSkipped = 0;

% -------------------------------------------------------------------------
% Loop through spreadsheet rows
% -------------------------------------------------------------------------
for iRow = 1:height(T)

    variableType = GLOBESINK_safe_table_string(T.variable_type(iRow));
    variableName = GLOBESINK_safe_table_string(T.variable_name(iRow));
    netcdfName   = GLOBESINK_safe_table_string(T.netcdf_name(iRow));
    unitsStr = GLOBESINK_safe_table_string(T.units(iRow));
    descStr  = GLOBESINK_safe_table_string(T.variable_description(iRow));
 
    % Sanitize NetCDF variable name just in case
   netcdfName = regexprep(netcdfName, '[^A-Za-z0-9_]', '_');

    % Check path exists in uncertainties tree
    if ~isfield(monthly_maps, 'uncertainties')
        warning('monthly_maps.uncertainties does not exist. No uncertainty fields written.');
        break
    end

    if ~isfield(monthly_maps.uncertainties, variableType)
        nSkipped = nSkipped + 1;
        continue
    end

    if ~isfield(monthly_maps.uncertainties.(variableType), variableName)
        nSkipped = nSkipped + 1;
        continue
    end

    uStruct = monthly_maps.uncertainties.(variableType).(variableName);

    if ~isstruct(uStruct)
        nSkipped = nSkipped + 1;
        continue
    end

    % Need upper and/or lower structs
    hasUpperStruct = isfield(uStruct, 'upper') && isstruct(uStruct.upper);
    hasLowerStruct = isfield(uStruct, 'lower') && isstruct(uStruct.lower);

    if ~(hasUpperStruct || hasLowerStruct)
        nSkipped = nSkipped + 1;
        continue
    end

    for iU = 1:numel(uncTypes)
        uncType = uncTypes{iU};

        % -----------------------------
        % upper bound
        % -----------------------------
        if hasUpperStruct && isfield(uStruct.upper, uncType)
            dataUpper = uStruct.upper.(uncType);

            outVarUpper = GLOBESINK_make_uncertainty_var_name(netcdfName, uncType, 'upper');

            if GLOBESINK_validate_uncertainty_array(dataUpper, expectedSize, ...
                    sprintf('monthly_maps.uncertainties.%s.%s.upper.%s', variableType, variableName, uncType))

                if ~GLOBESINK_nc_var_exists(ncfile, outVarUpper)
                    GLOBESINK_write_uncertainty_variable( ...
                        ncfile, outVarUpper, dataUpper, fillValue, ...
                        unitsStr, ...
                        GLOBESINK_make_uncertainty_long_name(descStr, uncType, 'upper'), ...
                        netcdfName, variableType, variableName, uncType, 'upper', ...
                        expectedSize);

                    nWritten = nWritten + 1;
                else
                    warning('Skipping %s because it already exists in %s.', outVarUpper, ncfile);
                end
            else
                nSkipped = nSkipped + 1;
            end
        end

        % -----------------------------
        % lower bound
        % -----------------------------
        if hasLowerStruct && isfield(uStruct.lower, uncType)
            dataLower = uStruct.lower.(uncType);

            outVarLower = GLOBESINK_make_uncertainty_var_name(netcdfName, uncType, 'lower');

            if GLOBESINK_validate_uncertainty_array(dataLower, expectedSize, ...
                    sprintf('monthly_maps.uncertainties.%s.%s.lower.%s', variableType, variableName, uncType))

                if ~GLOBESINK_nc_var_exists(ncfile, outVarLower)
                    GLOBESINK_write_uncertainty_variable( ...
                        ncfile, outVarLower, dataLower, fillValue, ...
                        unitsStr, ...
                        GLOBESINK_make_uncertainty_long_name(descStr, uncType, 'lower'), ...
                        netcdfName, variableType, variableName, uncType, 'lower', ...
                        expectedSize);

                    nWritten = nWritten + 1;
                else
                    warning('Skipping %s because it already exists in %s.', outVarLower, ncfile);
                end
            else
                nSkipped = nSkipped + 1;
            end
        end
    end
end

GLOBESINK_append_to_global_history( ...
    ncfile, ...
    'Appended additive upper/lower uncertainty variables from monthly_maps.uncertainties for precision and total_systematic');

fprintf('Finished appending uncertainty variables to: %s\n', ncfile);
fprintf('Uncertainty variables written: %d\n', nWritten);
fprintf('Entries skipped: %d\n', nSkipped);

end

% =========================================================================
% Helper functions
% =========================================================================

function tf = GLOBESINK_validate_uncertainty_array(data, expectedSize, label)

tf = true;

if ~isnumeric(data)
    warning('Skipping %s because it is not numeric.', label);
    tf = false;
    return
end

sz = size(data);
if numel(sz) < 4
    sz(end+1:4) = 1;
end

if ~isequal(sz(1:4), expectedSize)
    warning('Skipping %s because size is [%s], expected [%s].', ...
        label, num2str(sz(1:4)), num2str(expectedSize));
    tf = false;
end

end

function outVar = GLOBESINK_make_uncertainty_var_name(baseNetcdfName, uncType, boundType)

switch uncType
    case 'precision'
        outVar = sprintf('%s_precision_%s', baseNetcdfName, boundType);
    case 'total_systematic'
        outVar = sprintf('%s_systematic_uncertainty_%s', baseNetcdfName, boundType);
    otherwise
        outVar = sprintf('%s_%s_%s', baseNetcdfName, uncType, boundType);
end

outVar = regexprep(outVar, '[^A-Za-z0-9_]', '_');

end

function longName = GLOBESINK_make_uncertainty_long_name(parentDescription, uncType, boundType)

if isempty(parentDescription)
    parentDescription = 'variable';
end

switch uncType
    case 'precision'
        longName = sprintf('%s 95%% confidence bound for precision uncertainty of %s', ...
            boundType, parentDescription);

    case 'total_systematic'
        longName = sprintf(['%s additive systematic uncertainty propagated from upper and lower ' ...
            'bounds of parameter values used in this dataset for %s'], ...
            boundType, parentDescription);

    otherwise
        longName = sprintf('%s uncertainty bound (%s) for %s', ...
            boundType, uncType, parentDescription);
end

end

function GLOBESINK_write_uncertainty_variable( ...
    ncfile, varname, data, fillValue, unitsStr, longName, ...
    parentNetcdfName, variableType, variableName, uncType, boundType, expectedSize)

nP = expectedSize(1);
nY = expectedSize(2);
nX = expectedSize(3);
nM = expectedSize(4);

nccreate(ncfile, varname, ...
    'Dimensions', {'depth', nP, 'lat', nY, 'lon', nX, 'month', nM}, ...
    'Datatype', 'single', ...
    'FillValue', fillValue);

dataOut = single(data);
dataOut(isnan(dataOut)) = fillValue;
ncwrite(ncfile, varname, dataOut);

ncwriteatt(ncfile, varname, 'long_name', longName);
ncwriteatt(ncfile, varname, 'coordinates', 'depth lat lon month');
ncwriteatt(ncfile, varname, 'source', 'monthly_maps.uncertainties');
ncwriteatt(ncfile, varname, 'parent_variable', parentNetcdfName);
% ncwriteatt(ncfile, varname, 'source_variable_type', variableType);
ncwriteatt(ncfile, varname, 'source_variable_name', variableName);
ncwriteatt(ncfile, varname, 'uncertainty_type', uncType);
ncwriteatt(ncfile, varname, 'bound_type', boundType);
ncwriteatt(ncfile, varname, 'comment', ...
    'Additive uncertainty field with same dimensions as parent variable.');

if ~isempty(strtrim(unitsStr))
    ncwriteatt(ncfile, varname, 'units', unitsStr);
else
    ncwriteatt(ncfile, netcdfName, 'units', '1');
end

end

function tf = GLOBESINK_nc_var_exists(ncfile, varname)
info = ncinfo(ncfile);
allNames = {info.Variables.Name};
tf = ismember(varname, allNames);
end

function len = GLOBESINK_get_dim_length(info, dimName)
len = [];
for i = 1:numel(info.Dimensions)
    if strcmp(info.Dimensions(i).Name, dimName)
        len = info.Dimensions(i).Length;
        return
    end
end
error('Dimension "%s" not found in NetCDF file.', dimName);
end

function GLOBESINK_append_to_global_history(ncfile, newEntry)
timestamp = datestr(now, 31);
entry = [timestamp ' : ' newEntry];

try
    oldHistory = ncreadatt(ncfile, '/', 'history');
    if isstring(oldHistory)
        oldHistory = char(oldHistory);
    end
    historyText = sprintf('%s\n%s', oldHistory, entry);
catch
    historyText = entry;
end

ncwriteatt(ncfile, '/', 'history', historyText);
end