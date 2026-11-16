function GLOBESINK_append_flux_metadata_to_netcdf(ncfile, flux_metadata)
% GLOBESINK_append_flux_metadata_to_netcdf(ncfile, flux_metadata)
%
% Append scalar flux metadata parameters to an existing NetCDF file.
%
% Each numeric field in flux_metadata becomes a scalar NetCDF variable,
% except the substructures:
%   flux_metadata.units
%   flux_metadata.descriptions
%
% Units and descriptions are taken from those substructures when present.
% For *_upper and *_lower fields, the units are copied from the base field,
% and the description is prefixed with "upper bound of " or
% "lower bound of ".
%
% Example:
%   append_flux_metadata_to_netcdf('GLOBESINK_monthly_maps.nc', flux_metadata)

if ~exist(ncfile, 'file')
    error('NetCDF file does not exist: %s', ncfile);
end

% Pull out optional metadata structs
unitsStruct = struct();
descStruct  = struct();

if isfield(flux_metadata, 'units') && isstruct(flux_metadata.units)
    unitsStruct = flux_metadata.units;
end

if isfield(flux_metadata, 'descriptions') && isstruct(flux_metadata.descriptions)
    descStruct = flux_metadata.descriptions;
end

fields = fieldnames(flux_metadata);
nWritten = 0;
nSkipped = 0;

for i = 1:numel(fields)
    fname = fields{i};

    % Skip helper substructures
    if strcmp(fname, 'units') || strcmp(fname, 'descriptions')
        continue
    end

    value = flux_metadata.(fname);

    % Only write numeric scalar values
    if ~(isnumeric(value) && isscalar(value))
        warning('Skipping flux_metadata.%s because it is not a numeric scalar.', fname);
        nSkipped = nSkipped + 1;
        continue
    end

    % NetCDF-safe variable name
    ncvar = regexprep(fname, '[^A-Za-z0-9_]', '_');

    % Check whether variable already exists
    if nc_var_exists(ncfile, ncvar)
        warning('Skipping %s because variable already exists in %s.', ncvar, ncfile);
        nSkipped = nSkipped + 1;
        continue
    end

    % Determine base name and bound type
    [baseName, boundType] = parse_bound_name(fname);

    % Resolve units
    unitsStr = '';
    if isfield(unitsStruct, fname)
        unitsStr = unitsStruct.(fname);
    elseif isfield(unitsStruct, baseName)
        unitsStr = unitsStruct.(baseName);
    end

    % Resolve description
    descStr = '';
    if isfield(descStruct, fname)
        descStr = descStruct.(fname);
    elseif isfield(descStruct, baseName)
        descStr = descStruct.(baseName);
    end

    % Modify description for bounds
    if ~isempty(descStr)
        switch boundType
            case 'lower'
                descStr = ['lower bound of ' descStr];
            case 'upper'
                descStr = ['upper bound of ' descStr];
        end
    else
        % fallback if no description available
        switch boundType
            case 'lower'
                descStr = ['lower bound of ' strrep(baseName, '_', ' ')];
            case 'upper'
                descStr = ['upper bound of ' strrep(baseName, '_', ' ')];
            otherwise
                descStr = strrep(fname, '_', ' ');
        end
    end

    % Choose NetCDF datatype
    if isa(value, 'double')
        dtype = 'double';
    elseif isa(value, 'single')
        dtype = 'single';
    elseif isinteger(value)
        dtype = class(value);
    else
        value = double(value);
        dtype = 'double';
    end

    % Create scalar variable (0-D)
    nccreate(ncfile, ncvar, 'Datatype', dtype);

    % Write value
    ncwrite(ncfile, ncvar, value);

    % Attributes
    ncwriteatt(ncfile, ncvar, 'long_name', descStr);
    ncwriteatt(ncfile, ncvar, 'source', 'flux_metadata');

    if ~isempty(unitsStr)
        ncwriteatt(ncfile, ncvar, 'units', unitsStr);
    end

    if strcmp(boundType, 'lower') || strcmp(boundType, 'upper')
        ncwriteatt(ncfile, ncvar, 'bounds_type', boundType);
        ncwriteatt(ncfile, ncvar, 'base_parameter', baseName);
    end

    nWritten = nWritten + 1;
end

% Add a helpful global attribute
append_to_global_history(ncfile, 'Appended scalar flux metadata parameters from flux_metadata structure');

fprintf('Appended flux metadata to %s\n', ncfile);
fprintf('Scalar metadata variables written: %d\n', nWritten);
fprintf('Skipped: %d\n', nSkipped);

end

% -------------------------------------------------------------------------
function [baseName, boundType] = parse_bound_name(fname)
% Detect *_lower or *_upper suffixes
if length(fname) > 6 && strcmp(fname(end-5:end), '_lower')
    baseName = fname(1:end-6);
    boundType = 'lower';
elseif length(fname) > 6 && strcmp(fname(end-5:end), '_upper')
    baseName = fname(1:end-6);
    boundType = 'upper';
else
    baseName = fname;
    boundType = '';
end
end

% -------------------------------------------------------------------------
function tf = nc_var_exists(ncfile, varname)
info = ncinfo(ncfile);
allNames = {info.Variables.Name};
tf = ismember(varname, allNames);
end

% -------------------------------------------------------------------------
function append_to_global_history(ncfile, newEntry)
timestamp = datestr(now, 31);
entry = [timestamp ' : ' newEntry];

try
    oldHistory = ncreadatt(ncfile, '/', 'history');
    if isstring(oldHistory), oldHistory = char(oldHistory); end
    historyText = sprintf('%s\n%s', oldHistory, entry);
catch
    historyText = entry;
end

ncwriteatt(ncfile, '/', 'history', historyText);
end