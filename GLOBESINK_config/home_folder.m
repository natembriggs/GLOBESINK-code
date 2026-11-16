function hf = home_folder()
% hf = home_folder();
%
% Root folder holding BiogeochemicalArgo/{data,plots}/, read from
% GLOBESINK_config.m (copy GLOBESINK_config_template.m to create it).

hf = GLOBESINK_config_field('home_folder');
