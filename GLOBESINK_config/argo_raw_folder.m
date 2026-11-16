function af = argo_raw_folder()
% af = argo_raw_folder();
%
% Root of the local Argo GDAC mirror (dac/, aux/, index/), read from
% GLOBESINK_config.m (copy GLOBESINK_config_template.m to create it).

af = GLOBESINK_config_field('argo_raw_folder');
