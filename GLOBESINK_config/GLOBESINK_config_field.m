function value = GLOBESINK_config_field(fieldname)
% value = GLOBESINK_config_field(fieldname);
%
% One field of the struct returned by GLOBESINK_config.m, with a clear error
% if the user has not yet created that file from the template.

if exist('GLOBESINK_config', 'file') ~= 2
    error('GLOBESINK:config', ['GLOBESINK_config.m not found. Copy ' ...
        'GLOBESINK_config/GLOBESINK_config_template.m to ' ...
        'GLOBESINK_config/GLOBESINK_config.m and set your local paths there.']);
end
cfg = GLOBESINK_config();
if ~isfield(cfg, fieldname) || isempty(cfg.(fieldname))
    error('GLOBESINK:config', 'GLOBESINK_config.m does not set cfg.%s.', fieldname);
end
value = cfg.(fieldname);
