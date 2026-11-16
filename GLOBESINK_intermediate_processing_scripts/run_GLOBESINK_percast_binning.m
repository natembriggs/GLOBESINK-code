% run_GLOBESINK_percast_binning.m

QC_text = '';
if ~apply_manual_QC; QC_text = [QC_text '_no_manual_QC']; end
if ~apply_auto_QC; QC_text = [QC_text '_no_auto_QC']; 
elseif remove_FDOM_spikes; QC_text = [QC_text '_remove_FDOM_spikes']; end
if remove_bbp_spike_clusters; QC_text = [QC_text '_auto_QC_big_spikes']; end
% QC_text = 'auto_baseline_QC_only';
% QC_text = 'auto_baseline_QC_only';
%     if exist('biofloat','var') % data already loaded into struct biofloat
%         pc_bins = GLOBESINK_per_profile_binning(biofloat,biofloat_QC,vars_to_bin);
%     else % load data float by float from individual .mat files
        disp('calculating percast bins')
        for fix = 1:length(float_WMOs_to_process) % 173 804
            this_WMO = float_WMOs_to_process(fix);
            if mod(fix,10)==0
                disp(['float ' num2str(fix) '/' num2str(length(float_WMOs_to_process))])
            end
%             disp(this_WMO)
            mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];  
            QC_fname = [mat_file_folder 'f' num2str(this_WMO) '_QC.mat'];
            cdom_QC_fname = [mat_file_folder  'f' num2str(this_WMO) '_cdom_QC.mat'];
            bin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins' QC_text '.mat'];
%             bin_fname = [mat_file_folder 'Clara_binning/' 'f' num2str(this_WMO) '_pc_bins.mat'];
            if exist(mat_fname,'file') && exist(QC_fname,'file')
                load(mat_fname)
                load(QC_fname)
                if exist(cdom_QC_fname,'file')
                    load(cdom_QC_fname)
                    float_names = fieldnames(biofloat_cdom_QC1);
                    biofloat_QC1.(float_names{1}).is_near_cdom_spike = biofloat_cdom_QC1.(float_names{1}).is_near_cdom_spike;
                end
                try

                [pc_bins1,bin_opts1] = GLOBESINK_per_profile_binning(biofloat1,biofloat_QC1,vars_to_bin,apply_manual_QC,apply_auto_QC,remove_bbp_spike_clusters,remove_FDOM_spikes);
                if ~isempty(pc_bins1)
                    save(bin_fname,'pc_bins1','bin_opts1')
                end
                catch
                    disp([mat_fname ' pc bin failed'])
                end
            else
                disp([num2str(mat_fname) ' not found'])
            end
        end
        if exist('bin_opts1','var')
            bin_opts = bin_opts1;
            save([GLOBESINK_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_bin_opts.mat'],'bin_opts')
        end
%     end
% end

% Add bathymetry to percast bins
% if isfield(GLOBESINK_opts,'add_bathymetry_to_casts') && GLOBESINK_opts.add_bathymetry_to_casts
%%
bathmat = load_global_bathymetry();
near_shelf_dist = 10;%74; % km
near_shelf_lat_window = round(near_shelf_dist/latlon_dist(bathmat.y(1),0,bathmat.y(2),0));

disp('adding bathymetry to percast bins')

for fix = 1:length(float_WMOs_to_process)
    this_WMO = float_WMOs_to_process(fix);
            if mod(fix,10)==0
                disp(['float ' num2str(fix) '/' num2str(length(float_WMOs_to_process))])
            end
    bin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins' QC_text '.mat'];
%     bin_fname = [mat_file_folder 'Clara_binning/' 'f' num2str(this_WMO) '_pc_bins.mat'];
    if exist(bin_fname,'file')
        load(bin_fname)
        if ~isempty(pc_bins1)
        fnames = fieldnames(pc_bins1);
        fname = fnames{1};
        lats = pc_bins1.(fname).LATITUDE; lons = pc_bins1.(fname).LONGITUDE;
        bath_z = nan(size(lats)); bath_z_nearby = nan(size(lats));
        
        lonix = interp1(bathmat.x,1:length(bathmat.x),lons,'nearest');
        latix = interp1(bathmat.y',1:length(bathmat.y),lats,'nearest');
        
        glat_ixs = find(~isnan(lats+lons));
        for ii = 1:length(glat_ixs)
            thislat = lats(glat_ixs(ii));
            near_shelf_lon_window = round(near_shelf_dist/latlon_dist(thislat,bathmat.x(1),thislat,bathmat.x(2)));

            bath_z(glat_ixs(ii)) = bathmat.z(latix(glat_ixs(ii)),lonix(glat_ixs(ii)));
            nearby_lat_ixs = latix(glat_ixs(ii))+(-near_shelf_lat_window:near_shelf_lat_window); 
            nearby_lon_ixs = lonix(glat_ixs(ii))+(-near_shelf_lon_window:near_shelf_lon_window); 
            nearby_lat_ixs = nearby_lat_ixs(is_between(nearby_lat_ixs,1,length(bathmat.y)));
            nearby_lon_ixs = nearby_lon_ixs(is_between(nearby_lon_ixs,1,length(bathmat.x)));
            bath_z_nearby(glat_ixs(ii)) = max(max(bathmat.z(nearby_lat_ixs,nearby_lon_ixs)));
        end
        pc_bins1.(fname).bath_Z = bath_z;
        pc_bins1.(fname).bath_Z_nearby = bath_z_nearby;
        save(bin_fname,'pc_bins1','bin_opts1')
        end

    end
end