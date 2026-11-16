function [bio_ix_table,bio_ix_table_latest,has_key_parameter_matrix] = get_BGC_profile_locations(key_import_variables,require_all_key_variables,...
    BGC_Argo_data_folder,redownload_bioargo_index_file,import_lat_limits,import_lon_limits,...
    start_month,start_day,end_month,end_day,import_year_limits,plot_profile_locations,color_by_date)
% [bio_ix_table,bio_ix_table_latest,has_key_parameter_matrix] =
% get_BGC_profile_locations(key_import_variables,require_all_key_variables,BGC_Argo_data_folder,redownload_bioargo_index_file,import_lat_limits,import_lon_limits,start_month,start_day,end_month,end_day,import_year_limits,plot_profile_locations,color_by_date);
% 
% This function downloads the BGC Argo index file containing the locations
% and times of all BGC Argo profiles, searches this table for user-specified
% criteria and returns the subset of this table matching the search
% criteria as a Matlab variable
%
% FUNCTION INPUTS
% key_import_variables - cell array list of BGC variables to include in search
% require_all_key_variables - logical variable. If TRUE, function will only
%   search for profiles with ALL key variables. If FALSE, function will
%   search for profiles with ANY key variables.
% download_home - home folder path to which BGC Argo profile index file should
%   be downloaded. This function will create a subfolder
%   BiogeochemicalArgo/data/ within download_home
% redownload_bioargo_index_file - If TRUE, forces the function to re-download the
%   bioargo index file. If FALSE, function will only download the index file
%   if it does not exist in the download home folder
% import_lat_limits - 1x2 array containing lower and upper latitude bound
%   (use [-90 90] for global data)
% import_lon_limits - 1x2 array containing lower and upper longitude bound
%   (use [-180 180] for global data)
% start_month,start_day,end_month,end_day - Used to specify time of year
%   bounds. For year-round data choose the following: 
%   start_month = 1; start_day = 1; end_month = 12; end_day = 31;
% import_year_limits - 1x2 array containing lower and upper year bounds;
% plot_profile_locations - set to TRUE if you want to plot profile locations within this function. 
%     color_by_date - Requires function plot3c.m. Otherwise defaults to FALSE;
%
% FUNCTION OUTPUTS
% bio_ix_table - full table of all BGC Argo profiles that match the input
%   conditions
% bio_ix_table_latest - subset table with the latest profile from each float in
%   bio_ix_table

% clear
remote_folder = 'ftp://ftp.ifremer.fr/ifremer/argo/';
% download_home = home_folder;
% download_home = 'c:\Users\insert_user_name\Documents\'; % pc example
% download_home = '~/Documents/'; % mac example
% key_import_variables = {'PRES','TEMP','PSAL','CHLA','BBP700','NITRATE','DOXY','DOWNWELLING_PAR','PH_IN_SITU_TOTAL'};
% require_all_key_variables = 1;
% import_lat_limits = [-90 90]; import_lon_limits = [-180 180]; % [-54.5 -40]; %
% start_month = 1; start_day = 1; end_month = 12; end_day = 31;
% import_year_limits = [2021 2021];
% redownload_bioargo_index_file = 0;
% plot_profile_locations = 1; % set to 1 if you want to plot profile locations within this function. 
%     color_by_date = 0; % Requires function plot3c.m. Otherwise defaults to 0;


is_physical_variable = ismember(key_import_variables,{'PRES','TEMP','PSAL'});


if exist(BGC_Argo_data_folder,'dir')

%cd(BGC_Argo_data_folder)
%%
ixfile_name = 'argo_synthetic-profile_index.txt';

%% download bioargo index file
if redownload_bioargo_index_file||~exist([BGC_Argo_data_folder ixfile_name],'file')
    urlwrite([remote_folder ixfile_name],[BGC_Argo_data_folder ixfile_name]);
end
%% import bioargo index file to Matlab
bio_ix_table = readtable([BGC_Argo_data_folder ixfile_name],'headerlines',8,'delimiter',',');
bio_folder_table = readtable([BGC_Argo_data_folder ixfile_name],'headerlines',9,'delimiter','/','readvariablenames',false);
bio_folder_table.Properties.VariableNames = {'dac','float','folder','misc'};
bio_ix_table = [bio_ix_table bio_folder_table(:,1:2)];
key_import_var_cats = categorical(key_import_variables);
total_keyvar_length = length(key_import_variables)-1;
for kvar_ix = 1:length(key_import_variables)
    total_keyvar_length = total_keyvar_length + length(key_import_variables{kvar_ix});
end
%%
bio_ix_table.parameters = categorical(bio_ix_table.parameters);
bio_ix_table = bio_ix_table(~isundefined(bio_ix_table.parameters),:);

bio_ix_table.year = floor(bio_ix_table.date/1e10); dateresid = bio_ix_table.date-bio_ix_table.year*1e10;
bio_ix_table.month = floor(dateresid/1e8); dateresid = dateresid-bio_ix_table.month*1e8;
bio_ix_table.day = floor(dateresid/1e6); dateresid = dateresid-bio_ix_table.day*1e6;
bio_ix_table.hour = floor(dateresid/1e4); dateresid = dateresid-bio_ix_table.hour*1e4;
bio_ix_table.minute = floor(dateresid/1e2); 
bio_ix_table.second = dateresid-bio_ix_table.minute*1e2;
bio_ix_table.mtime = datenum(bio_ix_table.year,bio_ix_table.month,bio_ix_table.day,bio_ix_table.hour,bio_ix_table.minute,bio_ix_table.second);
% find(isnan(bio_ix_table.date_update))
bio_ix_table = bio_ix_table(~isnan(bio_ix_table.date_update),:);
bio_ix_table.mtime_update = datenum(num2str(bio_ix_table.date_update),'yyyymmddHHMMSS');

%% find profiles containing key parameters

[parameter_strings_unique,~,full_parameter_ixs] = unique(bio_ix_table.parameters);
% unique_string_contains_all_parameters = false(size(parameter_strings_unique));
% unique_string_contains_some_parameters = false(size(parameter_strings_unique));
unique_has_key_parameter_matrix = false(size(parameter_strings_unique,1),length(key_import_variables));

for parameter_string_ix = 1:length(parameter_strings_unique)
    parameter_string  = char(parameter_strings_unique(parameter_string_ix));
    if length(parameter_string)>=total_keyvar_length || ~require_all_key_variables
        clear parameter_cells
        space_ixs = [0 find(parameter_string==' ') length(parameter_string)+1];
        for six = 1:length(space_ixs)-1
            parameter_cells{six,1} = parameter_string(space_ixs(six)+1:space_ixs(six+1)-1);
        end
        parameter_cats = categorical(parameter_cells);
        vars_in_file = ismember(key_import_var_cats,parameter_cats);
        unique_has_key_parameter_matrix(parameter_string_ix,:) = vars_in_file;
    end
end
%%

if require_all_key_variables
    good_unique_ixs = find(all(unique_has_key_parameter_matrix,2));
else
    good_unique_ixs = find(all(unique_has_key_parameter_matrix(:,is_physical_variable),2)&any(unique_has_key_parameter_matrix(:,~is_physical_variable),2));
end

has_right_parameters = ismember(full_parameter_ixs,good_unique_ixs);
bio_ix_table = bio_ix_table(has_right_parameters,:);
has_key_parameter_matrix = unique_has_key_parameter_matrix(full_parameter_ixs(has_right_parameters),:);

%% plot location of profiles containing key parameters
if plot_profile_locations
    load coastlines.mat
    % load monthly_clim.mat
    figure(1);clf;hold on
    title([{'BGC Argo profile locations by variable: '} key_import_variables(~is_physical_variable)] )
    % pcolor(monthly_clim.lon,monthly_clim.lat,monthly_clim.chl(:,:,11));shading flat
    c = -log10(now-bio_ix_table.mtime);
    plot(coastlon,coastlat,'k')
%     if exist('plot3c.m','file') && color_by_date
%         plot3c(bio_ix_table.longitude,bio_ix_table.latitude,c,'.');
%     else
        plot3(bio_ix_table.longitude,bio_ix_table.latitude,ones(height(bio_ix_table),1)*-5,'.','color',[0.7 0.7 0.7]);
%     end
    plot([import_lon_limits; import_lon_limits]',[import_lat_limits; import_lat_limits],'m')
    plot([import_lon_limits; import_lon_limits],[import_lat_limits; import_lat_limits]','m')
    if exist('plot3c.m','file') && color_by_date
        caxis([-3.2 -0.7])
        cbarlabel('-log_1_0 days ago');
    end
    xlim([-180 180])
    ylim([-90 90])
end
%% find location of profiles within latlon limits
right_region = is_between(bio_ix_table.latitude,import_lat_limits)&is_between(bio_ix_table.longitude,import_lon_limits);
bio_ix_table = bio_ix_table(right_region,:);
has_key_parameter_matrix = has_key_parameter_matrix(right_region,:);

% plot(bio_ix_table.longitude,bio_ix_table.latitude,'g.')
%% find and plot location of profiles within season and year limits

% right_season = is_between(bio_ix_table.month,import_month_limits);
if (start_month*100+start_day) > (end_month*100+end_day)
    right_season = (bio_ix_table.month*100+bio_ix_table.day) >= (start_month*100+start_day) | ...
        (bio_ix_table.month*100+bio_ix_table.day) <= (end_month*100+end_day);
else
    right_season = (bio_ix_table.month*100+bio_ix_table.day) >= (start_month*100+start_day) & ...
        (bio_ix_table.month*100+bio_ix_table.day) <= (end_month*100+end_day);    
end
right_year = is_between(bio_ix_table.year,import_year_limits);
bio_ix_table = bio_ix_table(right_season&right_year,:);
has_key_parameter_matrix = has_key_parameter_matrix(right_season&right_year,:);


if plot_profile_locations
    c = -log10(now-bio_ix_table.mtime);
    all_years = unique(bio_ix_table.year(~isnan(bio_ix_table.year)));
    plot_symbols = '+oxv^*._'; plot_symbols = repmat(plot_symbols,1,10);
    clear h
    for yix = 1:length(all_years)
        g = bio_ix_table.year == all_years(yix);
        if exist('plot3c.m','file') && color_by_date
            plot_symbols = plot_symbols(plot_symbols~='_');
            h(yix) = plot3c(bio_ix_table.longitude(g),bio_ix_table.latitude(g),c(g),c(g),[plot_symbols(yix)]);
        else
            h(yix) = plot(bio_ix_table.longitude(g),bio_ix_table.latitude(g),[plot_symbols(yix)]);
        end
        set(h(yix),'linewidth',2)
    end
    if exist('h','var')
        legend(h,num2str(all_years));
    end
end

%% find latest profile from each float
bio_ix_table_recent_first = sortrows(bio_ix_table,'mtime','descend');
[~,uix] = unique(bio_ix_table_recent_first.float,'first');
bio_ix_table_latest = bio_ix_table_recent_first(uix,:);
else
    disp(['folder not found: ' download_home])
end