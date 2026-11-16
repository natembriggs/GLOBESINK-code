function out = GLOBESINK_safe_table_string(val)
% Safely convert table string/cell/missing to char

if ismissing(val)
    out = '';
    return
end

if isstring(val)
    out = char(strtrim(val));
elseif ischar(val)
    out = strtrim(val);
elseif iscell(val)
    out = char(strtrim(string(val)));
else
    out = '';
end

end