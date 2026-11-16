% GLOBESINK_BGC_Argo_data_processing_v3.m

clear

download_home = home_folder;

% set_GLOBESINK_options_GLOBESINK_global;
set_GLOBESINK_options_GLOBESINK_global_2025;
% set_GLOBESINK_options_UVP_floats;
% set_GLOBESINK_options_GLOBESINK_global_2026;
% set_GLOBESINK_options_global_FDOM;
% set_GLOBESINK_options_LAS;
% set_GLOBESINK_options_ICB;
% set_GLOBESINK_options_ICB_O2;
% set_GLOBESINK_options_ASBAN;

%% Set data and plot folders
[BGC_Argo_data_folder,BGC_Argo_plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home);
mat_file_folder = [download_home 'BiogeochemicalArgo/single_float_data_mat_format/'];
%% Look up float profiles by variable, location, and time
if ~isfield(GLOBESINK_opts,'set_float_WMOs_manually') || ~GLOBESINK_opts.set_float_WMOs_manually % if GLOBESINK_opts.set_float_WMOs_manually variable doesn't exist or if it is set to zero
[bio_ix_table,bio_ix_table_latest] = get_BGC_profile_locations(GLOBESINK_opts.key_import_variables,GLOBESINK_opts.require_all_key_variables,...
    BGC_Argo_data_folder,GLOBESINK_opts.redownload_bioargo_index_file,GLOBESINK_opts.import_lat_limits,GLOBESINK_opts.import_lon_limits,...
    GLOBESINK_opts.start_month,GLOBESINK_opts.start_day,GLOBESINK_opts.end_month,GLOBESINK_opts.end_day,GLOBESINK_opts.import_year_limits,GLOBESINK_opts.plot_profile_locations,GLOBESINK_opts.color_by_date);
float_WMOs = bio_ix_table_latest.float;
[bio_file_ix_table,bio_file_ix_table_latest] = get_bio_index_profile_locations(GLOBESINK_opts.key_import_variables,GLOBESINK_opts.require_all_key_variables,...
    BGC_Argo_data_folder,GLOBESINK_opts.redownload_bioargo_index_file,GLOBESINK_opts.import_lat_limits,GLOBESINK_opts.import_lon_limits,...
    GLOBESINK_opts.start_month,GLOBESINK_opts.start_day,GLOBESINK_opts.end_month,GLOBESINK_opts.end_day,GLOBESINK_opts.import_year_limits,GLOBESINK_opts.plot_profile_locations,GLOBESINK_opts.color_by_date);
end
if isfield(GLOBESINK_opts,'set_float_WMOs_manually') && GLOBESINK_opts.set_float_WMOs_manually == 1  % if GLOBESINK_opts.set_float_WMOs_manually variable does exist and if it is set to one
    float_WMOs = float_WMO_manual_list;
end
%% Get float metadata table
% if GLOBESINK_opts.download_metadata
    bio_metadata_ix_table = get_Argo_metadata_table(float_WMOs,BGC_Argo_data_folder,GLOBESINK_opts.redownload_metadata_index_file);
% end
%% Download float metadata
if GLOBESINK_opts.download_metadata
    download_BGC_Argo_metadata(bio_metadata_ix_table,BGC_Argo_data_folder);
end
%% Get float type metadata
if GLOBESINK_opts.get_float_type_metadata
    bio_metadata_ix_table = get_Argo_float_type(bio_metadata_ix_table,BGC_Argo_data_folder);
end
%% Get bbp sensor models
if GLOBESINK_opts.get_bbp700_sensor_model
    GLOBESINK_opts.sensor_names_to_find = {'BACKSCATTERINGMETER_BBP700'};
    bio_metadata_ix_table = get_Argo_sensor_model_names(bio_metadata_ix_table,GLOBESINK_opts.sensor_names_to_find,BGC_Argo_data_folder);
end
if strcmp(GLOBESINK_opts.datafile_name,'ASBAN')
    gfs = ismember(bio_metadata_ix_table.OPERATING_INSTITUTION,"NOC");
    bio_metadata_ix_table = bio_metadata_ix_table(gfs,:);
    float_WMOs = bio_metadata_ix_table.float;%float_WMOs(gfs);
end
%% Look up float profiles by float WMO
save([GLOBESINK_data_folder 'float_WMOs_' GLOBESINK_opts.datafile_name '.mat'],'float_WMOs')
if any(float_WMOs)
    % GLOBESINK_opts.redownload_bioargo_index_file = 0;
    [bio_ix_table_by_float,bio_ix_table_latest_by_float] = get_BGC_profile_locations_by_WMO(float_WMOs,BGC_Argo_data_folder,GLOBESINK_opts.redownload_bioargo_index_file,GLOBESINK_opts.plot_profile_locations,GLOBESINK_opts.color_by_date);
    [bio_file_ix_table_by_float,bio_file_ix_table_latest_by_float] = get_bio_file_profile_locations_by_WMO(float_WMOs,BGC_Argo_data_folder,GLOBESINK_opts.redownload_bioargo_index_file,GLOBESINK_opts.plot_profile_locations,GLOBESINK_opts.color_by_date);
end
%% Download float data
if GLOBESINK_opts.download_data
    if GLOBESINK_opts.download_full_float_data
        download_status = download_BGC_Argo_data(bio_ix_table_by_float,BGC_Argo_data_folder,GLOBESINK_opts.redownload_GDAC_files_if_newer);
    else
        download_status = download_BGC_Argo_data(bio_ix_table,BGC_Argo_data_folder,GLOBESINK_opts.redownload_GDAC_files_if_newer);
    end
end
%% Download Bio files
if isfield(GLOBESINK_opts,'download_bio_files')&&GLOBESINK_opts.download_bio_files
    if GLOBESINK_opts.download_full_float_data
        download_status = download_BGC_Argo_bio_files(bio_file_ix_table_by_float,BGC_Argo_data_folder,GLOBESINK_opts.redownload_GDAC_files_if_newer);
    else
        download_status = download_BGC_Argo_bio_files(bio_file_ix_table,BGC_Argo_data_folder,GLOBESINK_opts.redownload_GDAC_files_if_newer);
    end
end
%% Define floats WMOs to reprocess (saving in Matlab format, QCing, and binning)
if GLOBESINK_opts.download_data && isfield(GLOBESINK_opts,'process_only_newly_downloaded_floats') && GLOBESINK_opts.process_only_newly_downloaded_floats
    if GLOBESINK_opts.download_full_float_data
        float_WMOs_to_process = unique(bio_ix_table_by_float.float(download_status));
    else
        float_WMOs_to_process = unique(bio_ix_table.float(download_status));
    end
    disp(['processing only newly downloaded floats (n=' num2str(length(float_WMOs_to_process)) ')'])
else
    float_WMOs_to_process = float_WMOs;
    disp(['processing all floats (n=' num2str(length(float_WMOs_to_process)) ')'])
end

if isfield(GLOBESINK_opts,'reprocessing_start_date') 
    if GLOBESINK_opts.download_full_float_data
        float_WMOs_to_process = unique(bio_ix_table_by_float.float(bio_ix_table_by_float.mtime>GLOBESINK_opts.reprocessing_start_date));
    else
        float_WMOs_to_process = unique(bio_ix_table.float(bio_ix_table.mtime>GLOBESINK_opts.reprocessing_start_date));
    end
    disp(['processing only floats updated after ' datestr(GLOBESINK_opts.reprocessing_start_date) ...
        ' (n=' num2str(length(float_WMOs_to_process)) ')'])
end
%% Load float data
if GLOBESINK_opts.load_data
    str = 'y';
    if GLOBESINK_opts.download_data && ~any(download_status)
        prompt = 'continue despite not downloading data? y/n [n]: ';
        str = input(prompt,'s');
    end

    if strcmp(str,'y')||strcmp(str,'Y')
        if isfield(GLOBESINK_opts,'optional_variables')
            vars_to_load = [GLOBESINK_opts.key_import_variables GLOBESINK_opts.optional_variables];
        else
            vars_to_load = GLOBESINK_opts.key_import_variables;
        end
        if GLOBESINK_opts.load_full_float_data
            biofloat = load_BGC_Argo_data(bio_ix_table_by_float,vars_to_load,BGC_Argo_data_folder,GLOBESINK_opts.include_adjusted_data,GLOBESINK_opts.include_QC_flags);
        else
            biofloat = load_BGC_Argo_data(bio_ix_table,vars_to_load,BGC_Argo_data_folder,GLOBESINK_opts.include_adjusted_data,GLOBESINK_opts.include_QC_flags);
        end
    end
end

%% Merge realtime and delayed mode data
if GLOBESINK_opts.merge_RT_and_DM_data && GLOBESINK_opts.load_data && exist('biofloat','var')
    biofloat = GLOBESINK_merge_RT_DM_data(biofloat);
end

%% Save individual float mat files

if isfield(GLOBESINK_opts,'save_individual_float_mat_files') && GLOBESINK_opts.save_individual_float_mat_files %&& exist('biofloat','var')
    GLOBESINK_save_individual_float_mat_files;
end

%% Save data in mat format
if GLOBESINK_opts.save_data_mat_format
    if exist('biofloat','var')
        save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '.mat'],'biofloat')
    elseif isfield(GLOBESINK_opts,'save_individual_float_mat_files') && GLOBESINK_opts.save_individual_float_mat_files 
        GLOBESINK_combine_individual_float_mat_files;
        save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '.mat'],'biofloat')
    elseif exist([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '.mat'],'file')
        load([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '.mat'])
    end
end

%% Save metadata in mat format
if ~isfield(GLOBESINK_opts,'optional_variables')
    GLOBESINK_opts.optional_variables = {};
end
if ~exist('bio_ix_table','var')
    bio_ix_table = bio_ix_table_by_float; 
    bio_ix_table_latest = bio_ix_table_latest_by_float;
end
save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_metadata.mat'],...
    'bio_ix_table','bio_ix_table_by_float','bio_ix_table_latest_by_float','bio_ix_table_latest',...
    'bio_metadata_ix_table','GLOBESINK_opts')

% save('~/Desktop/tmp.mat')
%%
plot_QC_depth_sections = 0;
plot_QC_tz_sections = 0;

%% auto QC cdom
if isfield(GLOBESINK_opts,'cdom_QC') && GLOBESINK_opts.cdom_QC
    run_GLOBESINK_auto_QC_cdom_spikes;
end

%% Auto QC float bbp
if isfield(GLOBESINK_opts,'QC_float_bbp') && GLOBESINK_opts.QC_float_bbp
    run_GLOBESINK_auto_QC_bbp;
end

%% manual QC
% float_WMOs_to_process = 6901495;
if isfield(GLOBESINK_opts,'QC_float_bbp') && GLOBESINK_opts.QC_float_bbp
    run_GLOBESINK_manual_QC_bbp;
end

%%
if GLOBESINK_opts.save_data_mat_format
    if exist('biofloat_QC','var')
        save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_QC.mat'],'biofloat_QC')
    elseif isfield(GLOBESINK_opts,'save_individual_float_mat_files') && GLOBESINK_opts.save_individual_float_mat_files 
        GLOBESINK_combine_individual_float_QC;
        save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_QC.mat'],'biofloat_QC')
    elseif exist([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_QC.mat'],'file')
        load([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_QC.mat'])
    end
end
%% percast bins
if isfield(GLOBESINK_opts,'optional_variables')
    vars_to_bin = [GLOBESINK_opts.key_import_variables GLOBESINK_opts.optional_variables];
else
    vars_to_bin = GLOBESINK_opts.key_import_variables;
end

apply_manual_QC = 1; 
apply_auto_QC = 1;
remove_FDOM_spikes = 0;
remove_bbp_spike_clusters = 0;

if isfield(GLOBESINK_opts,'calculate_percast_bins') && GLOBESINK_opts.calculate_percast_bins
    run_GLOBESINK_percast_binning;
end
%% Plot percast bins
plot_percast_bins = 0;
% QC_text = '_not_cleaned'; 
if exist('plot_percast_bins','var') && plot_percast_bins
    GLOBESINK_plot_percast_bins;
end

%% plot surface size maps
if isfield(GLOBESINK_opts,'plot_surface_size') && GLOBESINK_opts.plot_surface_size
    GLOBESINK_plot_surface_size_maps;
end
%% plot surface size timeseries
if isfield(GLOBESINK_opts,'plot_surface_size') && GLOBESINK_opts.plot_surface_size
    GLOBESINK_plot_pc_bin_climatological_timeseries;
end

%% Plot individual BGC float sections
project_plot_folder = [BGC_Argo_plot_folder GLOBESINK_opts.datafile_name '/'];
if ~exist(project_plot_folder,'dir')
    mkdir(project_plot_folder)
end

if GLOBESINK_opts.plot_individual_float_sections
    if exist('biofloat','var') % data already loaded into struct biofloat
        plot_individual_BGC_float_sections(biofloat,GLOBESINK_opts.vnames_to_plot,project_plot_folder,...
            GLOBESINK_opts.plot_individual_maps,GLOBESINK_opts.plot_spikes,GLOBESINK_opts.plot_lat_limits,GLOBESINK_opts.plot_lon_limits,GLOBESINK_opts.plot_depth_range);
    else % load data float by float from individual .mat files
        for fix = 1:length(float_WMOs)
            this_WMO = float_WMOs(fix);
            mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];  
            if exist(mat_fname,'file')
                load(mat_fname)
                plot_individual_BGC_float_sections(biofloat1,GLOBESINK_opts.vnames_to_plot,project_plot_folder,...
                    GLOBESINK_opts.plot_individual_maps,GLOBESINK_opts.plot_spikes,GLOBESINK_opts.plot_lat_limits,GLOBESINK_opts.plot_lon_limits,GLOBESINK_opts.plot_depth_range);
            else
                disp([num2str(mat_fname) ' not found'])
            end
        end
    end
end
%% Plot individual BGC float profiles
profile_plot_folder = [project_plot_folder 'profiles/'];
if isfield(GLOBESINK_opts,'plot_individual_float_profiles')&&GLOBESINK_opts.plot_individual_float_profiles
    if exist('biofloat','var') % data already loaded into struct biofloat
        plot_individual_BGC_float_profiles(biofloat,GLOBESINK_opts.vnames_to_plot,profile_plot_folder,...
            GLOBESINK_opts.plot_individual_maps,GLOBESINK_opts.plot_spikes,GLOBESINK_opts.plot_lat_limits,plot_lon_limits,GLOBESINK_opts.plot_depth_range);
    else % load data float by float from individual .mat files
        %%
        for fix = 1:length(float_WMOs)
            this_WMO = float_WMOs(fix);
            mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];  
            if exist(mat_fname,'file')
                load(mat_fname)
                plot_individual_BGC_float_profiles(biofloat1,GLOBESINK_opts.vnames_to_plot,profile_plot_folder,...
                    GLOBESINK_opts.plot_individual_maps,GLOBESINK_opts.plot_spikes,GLOBESINK_opts.plot_lat_limits,plot_lon_limits,GLOBESINK_opts.plot_depth_range);
            else
                disp([num2str(mat_fname) ' not found'])
            end
        end
    end
end

%% Plot combined BGC float sections

if isfield(GLOBESINK_opts,'plot_combined_float_sections')&&GLOBESINK_opts.plot_combined_float_sections
    plot_all_BGC_float_sections_combined(biofloat,GLOBESINK_opts.vnames_to_plot,BGC_Argo_plot_folder,...
        GLOBESINK_opts.plot_spikes,GLOBESINK_opts.plot_lat_limits,plot_lon_limits,GLOBESINK_opts.plot_depth_range);
end


%% Standalone scripts to create final binned products. 
% Combine per profile bins into monthly per-float bins and climatologies
% GLOBESINK_monthly_binning4.m % Run this first with add_deep_bbp_offsets = 0; recalc_monthly_bins = 1;

% Align nearby float bbp at depth
% get_GLOBESINK_deep_offsets.m

% Rerun monthly binning and climatologies with deep offsets to bbp data
% GLOBESINK_monthly_binning4.m % Run this again with add_deep_bbp_offsets = 1; 

% Calculate POC and POC flux from monthly binned products (final GLOBESINK dataset)
% GLOBESINK_POC_flux_calculation_v2.m % run to calculate POC fluxes

% Output netcdf files of GLOBESINK dataset
% GLOBESINK_netcdf_file_creation.m