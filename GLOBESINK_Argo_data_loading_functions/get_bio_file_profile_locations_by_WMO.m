function [bio_ix_table,bio_ix_table_latest] = get_bio_file_profile_locations_by_WMO(float_WMOs,...
    BGC_Argo_data_folder,redownload_bioargo_index_file,plot_profile_locations,color_by_date)
% [bio_file_ix_table,bio_file_ix_table_latest] = get_bio_file_profile_locations_by_WMO(float_WMOs,download_home,redownload_bioargo_index_file,plot_profile_locations,color_by_date);
% 
% This function downloads the BGC Argo index file containing the locations
% and times of all BGC Argo profiles from a list of specified float WMOs
% and returns this information as a Matlab table
%
% FUNCTION INPUTS
% float_WMOs - list of BGC Argo float WMOs 
% download_home - home folder path to which BGC Argo profile index file should
%   be downloaded. This function will create a subfolder
%   BiogeochemicalArgo/data/ within download_home
% redownload_bioargo_index_file - If TRUE, forces the function to re-download the
%   bioargo index file. If FALSE, function will only download the index file
%   if it does not exist in the download home folder
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




if exist(BGC_Argo_data_folder,'dir')

    if ispc
        if BGC_Argo_data_folder(end) ~= '\'
            BGC_Argo_data_folder(end+1) = '\';
        end
    else
        if BGC_Argo_data_folder(end) ~= '/'
            BGC_Argo_data_folder(end+1) = '/';
        end
    end

%     local_folder = [BGC_Argo_data_folder 'BiogeochemicalArgo/data/'];
    if ispc
        BGC_Argo_data_folder(BGC_Argo_data_folder=='/') = '\';
%         local_folder(BGC_Argo_data_folder=='/') = '\';
    end

    if ~exist(BGC_Argo_data_folder,'dir')
        mkdir(BGC_Argo_data_folder)
    end

% cd(local_folder)
%%
ixfile_name = 'argo_bio-profile_index.txt';

%% download bioargo index file
if redownload_bioargo_index_file||~exist([BGC_Argo_data_folder ixfile_name],'file')
    urlwrite([remote_folder ixfile_name],[BGC_Argo_data_folder ixfile_name]);
end
%% import bioargo index file to Matlab
bio_ix_table = readtable([BGC_Argo_data_folder ixfile_name],'headerlines',8,'delimiter',',');
bio_folder_table = readtable([BGC_Argo_data_folder ixfile_name],'headerlines',9,'delimiter','/','readvariablenames',false);
bio_folder_table.Properties.VariableNames = {'dac','float','folder','misc'};
bio_ix_table = [bio_ix_table bio_folder_table(:,1:2)];
%%
bio_ix_table.parameters = categorical(bio_ix_table.parameters);
bio_ix_table = bio_ix_table(~isundefined(bio_ix_table.parameters),:);


%% select good floats
is_good_float = (ismember(bio_ix_table.float,float_WMOs));
bio_ix_table = bio_ix_table(is_good_float,:);

%% add time variables to float table
bio_ix_table.year = floor(bio_ix_table.date/1e10); dateresid = bio_ix_table.date-bio_ix_table.year*1e10;
bio_ix_table.month = floor(dateresid/1e8); dateresid = dateresid-bio_ix_table.month*1e8;
bio_ix_table.day = floor(dateresid/1e6); dateresid = dateresid-bio_ix_table.day*1e6;
bio_ix_table.hour = floor(dateresid/1e4); dateresid = dateresid-bio_ix_table.hour*1e4;
bio_ix_table.minute = floor(dateresid/1e2); 
bio_ix_table.second = dateresid-bio_ix_table.minute*1e2;
bio_ix_table.mtime = datenum(bio_ix_table.year,bio_ix_table.month,bio_ix_table.day,bio_ix_table.hour,bio_ix_table.minute,bio_ix_table.second);

bio_ix_table.mtime_update = datenum(num2str(bio_ix_table.date_update),'yyyymmddHHMMSS');

%% plot location of profiles from good floats

if plot_profile_locations
    load coastlines.mat
    % load monthly_clim.mat
    figure(2);clf;hold on
    title(['Bio index profile locations by float WMO'])
    % pcolor(monthly_clim.lon,monthly_clim.lat,monthly_clim.chl(:,:,11));shading flat
    c = -log10(now-bio_ix_table.mtime);
    plot(coastlon,coastlat,'k')
    all_years = unique(bio_ix_table.year(~isnan(bio_ix_table.year)));
    plot_symbols = '+oxv^*..'; plot_symbols = repmat(plot_symbols,1,10);
    clear h
    for yix = 1:length(all_years)
        g = bio_ix_table.year == all_years(yix);
        if exist('plot3c.m','file') && color_by_date && any(g)
            plot_symbols = plot_symbols(plot_symbols~='_');
            h(yix) = plot3c(bio_ix_table.longitude(g),bio_ix_table.latitude(g),c(g),c(g),[plot_symbols(yix)]);
        else
            h(yix) = plot(bio_ix_table.longitude(g),bio_ix_table.latitude(g),[plot_symbols(yix)]);
        end
        set(h(yix),'linewidth',2)
    end
    legend(h,num2str(all_years));
end

%% find latest profile from each float
bio_ix_table_recent_first = sortrows(bio_ix_table,'mtime','descend');
[~,uix] = unique(bio_ix_table_recent_first.float,'first');
bio_ix_table_latest = bio_ix_table_recent_first(uix,:);
else
    disp(['folder not found: ' BGC_Argo_data_folder])
end