% set_GLOBESINK_options_GLOBESINK_global_2025.m

GLOBESINK_opts.require_all_key_variables = 1;
% GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','BBP700','CHLA'};  GLOBESINK_opts.optional_variables = {'DOXY','CP660','BBP532','BBP470','CDOM','DOWNWELLING_PAR'};
GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','BBP700','CHLA'};  GLOBESINK_opts.optional_variables = {'BBP700_2','DOXY','CP660','BBP532','BBP470','CDOM','NITRATE','PH_IN_SITU_TOTAL','DOWNWELLING_PAR','DOWN_IRRADIANCE490','DOWN_IRRADIANCE412','DOWN_IRRADIANCE380'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','BBP700','CHLA','DOXY'}; GLOBESINK_opts.optional_variables = {'CDOM'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','CHLA','BBP700','NITRATE','DOXY'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','NITRATE'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','BBP700','CHLA','NITRATE'};  GLOBESINK_opts.optional_variables = {'DOXY','CP660','BBP532','BBP470','CDOM'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','CHLA','BBP700','CDOM','NITRATE','DOXY','DOWNWELLING_PAR','PH_IN_SITU_TOTAL'};
%         GLOBESINK_opts.key_import_variables = {'PRES','TEMP','PSAL','CP660'}; % 'BBP700'}; % 'BBP532'}; % 'BBP470'}; % 'TURBIDITY'}; % 


% GLOBESINK_opts.import_lat_limits = [56.75 63.1]; GLOBESINK_opts.import_lon_limits = [-33 -16.5]; GLOBESINK_opts.datafile_name = 'ICB'; % ICB
% GLOBESINK_opts.import_lat_limits = [55,62]; GLOBESINK_opts.import_lon_limits = [-55,-48]; GLOBESINK_opts.datafile_name = 'LAS'; % ICB

% GLOBESINK_opts.import_lat_limits = [-48 64.5]; GLOBESINK_opts.import_lon_limits = [-82 -0]; GLOBESINK_opts.datafile_name = 'ASBAN'; %'six_parameters_global';% ASBAN
%         GLOBESINK_opts.import_lat_limits = [44 52]; GLOBESINK_opts.import_lon_limits = [155 170]; GLOBESINK_opts.datafile_name = 'K2'; %K2
%         GLOBESINK_opts.import_lat_limits = [-53 -47]; GLOBESINK_opts.import_lon_limits = [70 82]; %[-54.5 -30];
GLOBESINK_opts.import_lat_limits = [-90 90]; GLOBESINK_opts.import_lon_limits = [-180 180]; GLOBESINK_opts.datafile_name = 'GLOBESINK_global_2025'; % GLOBESINK_opts.datafile_name = 'six_parameters_global'; %
% GLOBESINK_opts.import_lat_limits = [64 73]; GLOBESINK_opts.import_lon_limits = [-10 14]; GLOBESINK_opts.datafile_name = 'NOS'; % GLOBESINK_opts.datafile_name = 'six_parameters_global'; %
%         GLOBESINK_opts.import_lat_limits = [-90 90]; GLOBESINK_opts.import_lon_limits = [-180 180]; % GLOBESINK_opts.datafile_name = 'six_parameters_global'; %
%         GLOBESINK_opts.import_lat_limits = [-55 -47]; GLOBESINK_opts.import_lon_limits = [65 80]; GLOBESINK_opts.datafile_name = 'Kerguelen';% KERGUELEN
%         GLOBESINK_opts.import_lat_limits = [-50 -47]; GLOBESINK_opts.import_lon_limits = [75 82]; GLOBESINK_opts.datafile_name = 'Kerguelen_Anita';% KERGUELEN
%         GLOBESINK_opts.import_lat_limits = [-63 -51]; GLOBESINK_opts.import_lon_limits = [-92 -87]; GLOBESINK_opts.datafile_name = 'CUSTARD';% [-54.5 -40]; %

GLOBESINK_opts.start_month = 1; GLOBESINK_opts.start_day = 1; GLOBESINK_opts.end_month = 12; GLOBESINK_opts.end_day = 31;
% GLOBESINK_opts.start_month = 5; GLOBESINK_opts.start_day = 15; GLOBESINK_opts.end_month = 6; GLOBESINK_opts.end_day = 31;
GLOBESINK_opts.import_year_limits = [2010 2025]; %[2023 2023]; % [2010 2021]; %  
%         GLOBESINK_opts.import_year_limits = [2015 2017]; % [2023 2023]; % [2010 2022]; % 

GLOBESINK_opts.reprocessing_start_date = datenum(2004,8,1); % datenum(2024,8,1);

%  ????????? SET DOWNLOAD, PROCESSING AND PLOTTING OPTIONS ?????????
GLOBESINK_opts.redownload_bioargo_index_file = 0; % 1: re-download bio-argo index file (~30 MB); 0: don't re-download (will automatically download if it doesn't exist)
GLOBESINK_opts.plot_profile_locations = 0; % set to 1 if you want to plot profile locations within this function. 
    GLOBESINK_opts.color_by_date = 0; % Requires function plot3c.m. Otherwise defaults to 0;
GLOBESINK_opts.download_data = 0; 
GLOBESINK_opts.download_bio_files = 0; 
    GLOBESINK_opts.download_full_float_data = 0;
    GLOBESINK_opts.redownload_GDAC_files_if_newer = 1;
    GLOBESINK_opts.process_only_newly_downloaded_floats = 1;
    
GLOBESINK_opts.set_float_WMOs_manually = 0; % if you set this option script will ignore lat, lon, time, etc.
    % float_WMO_manual_list = 5906981;
    % float_WMO_manual_list = [5904397 5904467 5904468 5904471 5904472 5905991 5905992 5905994 5905995 5906033 5906034];%[6901525];
    % float_WMO_manual_list = [5905395 5905165]; GLOBESINK_opts.datafile_name = 'DUAL_BBP';
    if GLOBESINK_opts.set_float_WMOs_manually
        GLOBESINK_opts.download_full_float_data = 1;
    end
GLOBESINK_opts.download_metadata = 0;
    GLOBESINK_opts.redownload_metadata_index_file = 0;
    GLOBESINK_opts.get_float_type_metadata = 1;
    GLOBESINK_opts.get_bbp700_sensor_model = 1;
GLOBESINK_opts.load_data = 0;
    GLOBESINK_opts.load_full_float_data = 0;
    GLOBESINK_opts.merge_RT_and_DM_data = 1;
    GLOBESINK_opts.include_adjusted_data = 1; 
    GLOBESINK_opts.include_QC_flags = 1;
    GLOBESINK_opts.save_data_mat_format = 0; if ~isfield(GLOBESINK_opts,'datafile_name'); GLOBESINK_opts.datafile_name = 'test'; end %
GLOBESINK_opts.save_individual_float_mat_files = 0;
    GLOBESINK_opts.resave_individual_float_mat_files = 0;
    % GLOBESINK_opts.resave_only_newly_downloaded_floats = 1;
GLOBESINK_opts.QC_float_bbp = 0; GLOBESINK_opts.recalculate_bbp_QC = 0; %GLOBESINK_opts.QC_only_newly_downloaded_floats = 1;
GLOBESINK_opts.cdom_QC = 0; GLOBESINK_opts.recalculate_cdom_QC = 1; GLOBESINK_opts.recalc_cdom_baseline = 0;
GLOBESINK_opts.calculate_percast_bins = 1;
    GLOBESINK_opts.add_bathymetry_to_casts = GLOBESINK_opts.calculate_percast_bins;
GLOBESINK_opts.plot_surface_size = 0;
GLOBESINK_opts.plot_individual_float_sections = 0;
GLOBESINK_opts.plot_combined_float_sections = 0;
GLOBESINK_opts.plot_individual_float_profiles = 0;
    GLOBESINK_opts.vnames_to_plot = GLOBESINK_opts.key_import_variables(2:end);
%             for vix = 1:length(GLOBESINK_opts.vnames_to_plot); GLOBESINK_opts.vnames_to_plot{vix} = [GLOBESINK_opts.vnames_to_plot{vix} '_ADJUSTED']; end
%             GLOBESINK_opts.vnames_to_plot = {'TEMP_ADJUSTED','PSAL_ADJUSTED','NITRATE_ADJUSTED'};
    % GLOBESINK_opts.vnames_to_plot = {'TEMP','PSAL','CHLA','BBP700','NITRATE','DOXY','DOWNWELLING_PAR','PH_IN_SITU_TOTAL'};
    GLOBESINK_opts.plot_individual_maps = 0;
    GLOBESINK_opts.plot_spikes = 0;
    GLOBESINK_opts.plot_depth_range = [0 2000];
    GLOBESINK_opts.plot_lat_limits = GLOBESINK_opts.import_lat_limits; GLOBESINK_opts.plot_lon_limits = GLOBESINK_opts.import_lon_limits;
