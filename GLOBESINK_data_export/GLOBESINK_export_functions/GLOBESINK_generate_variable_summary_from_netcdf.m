function GLOBESINK_generate_variable_summary_from_netcdf(ncfile, outfile)
% GLOBESINK_generate_variable_summary_from_netcdf(ncfile, outfile)
%
% Generate a complete variable summary table from a NetCDF file.
%
% Columns:
%   GLOBESINK Netcdf Variable Name
%   Value (if variable is scalar)
%   Units (blank if unitless)
%   Argo Source Variable
%   Variable Size
%   Variable Description

info = ncinfo(ncfile);
vars = info.Variables;
n = numel(vars);

netcdfName = strings(n,1);
scalarValue = strings(n,1);
units = strings(n,1);
argoSourceVariable = strings(n,1);
variableSize = strings(n,1);
variableDescription = strings(n,1);

for i = 1:n

    v = vars(i);
    name = v.Name;

    netcdfName(i) = string(name);

    % Size and scalar value
    isScalarVariable = isempty(v.Dimensions) || isempty(v.Size) || isequal(v.Size, 1);

    if isScalarVariable
        variableSize(i) = "1";

        try
            val = ncread(ncfile, name);

            if isnumeric(val) && isscalar(val)
                scalarValue(i) = string(val);
            elseif islogical(val) && isscalar(val)
                scalarValue(i) = string(val);
            elseif ischar(val)
                scalarValue(i) = string(val);
            elseif isstring(val) && isscalar(val)
                scalarValue(i) = val;
            else
                scalarValue(i) = "";
            end

        catch
            scalarValue(i) = "";
        end

    else
        variableSize(i) = join(string(v.Size), "x");
        scalarValue(i) = "";
    end
    % Units, with unitless variables left blank
    u = GLOBESINK_get_att(v, 'units');
    units(i) = GLOBESINK_clean_units(u);

    % Description
    variableDescription(i) = GLOBESINK_get_att(v, 'long_name');

    % Argo source variable
    argoSourceVariable(i) = GLOBESINK_infer_source_variable(v, name);

end

T = table( ...
    netcdfName, ...
    scalarValue, ...
    units, ...
    argoSourceVariable, ...
    variableSize, ...
    variableDescription);

T.Properties.VariableNames = { ...
    'GLOBESINK Netcdf Variable Name', ...
    'Value (if variable is scalar)', ...
    'Units (blank if unitless)', ...
    'Argo Source Variable', ...
    'Variable Size', ...
    'Variable Description'};

writetable(T, outfile);

fprintf('Wrote complete variable summary to %s\n', outfile);

end

% =========================================================================
function val = GLOBESINK_get_att(v, attname)

val = "";

for i = 1:numel(v.Attributes)
    if strcmp(v.Attributes(i).Name, attname)
        val = string(v.Attributes(i).Value);
        return
    end
end

end

% =========================================================================
function unitsOut = GLOBESINK_clean_units(unitsIn)
% Leave units blank for unitless variables.

unitsOut = strtrim(string(unitsIn));

if ismissing(unitsOut) || strlength(unitsOut) == 0
    unitsOut = "";
    return
end

unitlessValues = ["1", "unitless", "dimensionless", "none", "NA", "N/A", "-"];

if any(strcmpi(unitsOut, unitlessValues))
    unitsOut = "";
end

end

% =========================================================================
function src = GLOBESINK_infer_source_variable(v, name)

src = "";

% Best case: original attribute from export script
att = GLOBESINK_get_att(v, 'source_variable_name');
if strlength(att) > 0
    src = att;
    return
end

% Uncertainty variables: use parent variable if present
parent = GLOBESINK_get_att(v, 'parent_variable');
if strlength(parent) > 0
    src = parent;
    return
end

% Fallback for uncertainty variables without parent_variable attribute
tokens = regexp(name, ...
    '^(.*?)(_precision_(upper|lower)|_systematic_uncertainty_(upper|lower))$', ...
    'tokens');

if ~isempty(tokens)
    src = string(tokens{1}{1});
    return
end

% Scalar parameters and coordinate variables stay blank
if isempty(v.Dimensions) || isempty(v.Size) || isequal(v.Size, 1) || ...
        ismember(string(name), ["pressure","lat","lon","month"])
    src = "";
    return
end

end