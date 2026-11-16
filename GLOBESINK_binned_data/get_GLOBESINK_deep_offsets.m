% get_GLOBESINK_deep_offsets.m

plot_folder = [home_folder 'BiogeochemicalArgo/plots/GLOBESINK_deep_offsets/'];

plot_offset_timeseries = 1;

recalc_initial_offsets = 1;
    initial_offset_scale_factor = 0.5;
recalc_second_offsets = 1;
    second_offset_scale_factor = 1;
recalc_third_offsets = 1;

plot_summary_stats = 0;

variable_types = {'baseline'};
variable_names = {'BBP700'};

max_dist = 2000; % km
% max_dist = 400; % km

comparison_depths = [450 950 1700];

download_home = home_folder; % Home folder path
[BGC_Argo_data_folder,BGC_Argo_plot_folder,GLOBESINK_folder] = get_BGC_Argo_data_and_plot_folders(download_home); % Function to get folders
bathmat = load_global_bathymetry(); % Load global bathymetry data

% Set up file and variable names
mat_file_folder = [download_home 'BiogeochemicalArgo/single_float_data_mat_format/'];
datafile_name = 'GLOBESINK_global_2025'; % Name of the file
    % version_text = 'beta20250611';
    % version_text = 'beta20260211';
    version_text = 'beta20260401';
% datafile_name = 'GLOBESINK_global'; % Name of the file
%     version_text = 'beta20241206_newbin';

load([GLOBESINK_folder 'BGC_Argo_data_' datafile_name '_metadata.mat'])
load([GLOBESINK_folder 'BGC_Argo_data_' datafile_name '_bin_opts.mat'])
float_WMOs = bio_ix_table_latest.float;

zbin_edges = bin_opts.zbin_edges; % Depth bin edges in meters

switch datafile_name 
    case 'GLOBESINK_global_2025'
        t_edges = datenum(2010,1:(12*15+6),1); % Time bin edges
    otherwise
        t_edges = datenum(2010,1:(12*14+9),1); % Time bin edges
end

exclude_near_shelf = 1;
apply_manual_QC = 1; 
apply_auto_QC = 1;
remove_FDOM_spikes = 0;
remove_bbp_spike_clusters = 0;

lat_interval = 4; lon_interval = 8;

QC_text = '';
if ~apply_manual_QC; QC_text = [QC_text '_no_manual_QC']; end
if ~apply_auto_QC; QC_text = [QC_text '_no_auto_QC']; 
elseif remove_FDOM_spikes; QC_text = [QC_text '_remove_FDOM_spikes']; end
if remove_bbp_spike_clusters; QC_text = [QC_text '_auto_QC_big_spikes']; end

res_text = '';
if lat_interval~=4 || lon_interval ~=8
    res_text = ['res_' num2str(lat_interval) '_' num2str(lon_interval)];
end
%%
if exclude_near_shelf; shelf_text = '';
else; shelf_text = '_alldepths'; end

load([GLOBESINK_folder 'BGC_Argo_monthly_bins_' datafile_name '_' version_text shelf_text QC_text '.mat'])

%%
if recalc_initial_offsets
    plot_folder1 = [plot_folder 'initial_offsets' num2str(max_dist) 'km/'];
    [deep_offset_tables] = GLOBESINK_deep_bbp_offsets(monthly_bins,t_edges,zbin_edges,...
        variable_types,variable_names,comparison_depths,float_WMOs,plot_folder1,plot_offset_timeseries,max_dist);
    save([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_initial' num2str(max_dist) 'km.mat'],'deep_offset_tables');
else
    load([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_initial' num2str(max_dist) 'km.mat']);
end
%% adjust monthly bins by initial offset (times initial offset scale factor)
monthly_bins2 = monthly_bins;
for vix = 1:length(variable_types)
    vtype = variable_types{vix};
    vname = variable_names{vix};
    if any(float_WMOs~=deep_offset_tables.(vtype).(vname).float_WMOs)
        disp('float WMOs do not match')
    else
        for fix = 1:length(float_WMOs)
            this_offset = deep_offset_tables.(vtype).(vname).deep_offsets(fix);
            if ~isnan(this_offset)
                monthly_bins2.(vtype).(vname)(:,:,fix) = monthly_bins2.(vtype).(vname)(:,:,fix) + this_offset*initial_offset_scale_factor;
            end
        end
    end
end

%%
if recalc_second_offsets
    plot_folder2 = [plot_folder 'second_offsets' num2str(max_dist) 'km/'];
    if ~exist(plot_folder2,'dir')
        mkdir(plot_folder2)
    end
    [deep_offset_tables2] = GLOBESINK_deep_bbp_offsets(monthly_bins2,t_edges,zbin_edges,...
        variable_types,variable_names,comparison_depths,float_WMOs,plot_folder2,plot_offset_timeseries,max_dist);
    save([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_secondary' num2str(max_dist) 'km.mat'],'deep_offset_tables2');
else
    load([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_secondary' num2str(max_dist) 'km.mat']);
end

%% adjust monthly bins by secondary offset (times secondary offset scale factor)
monthly_bins3 = monthly_bins2;
for vix = 1:length(variable_types)
    vtype = variable_types{vix};
    vname = variable_names{vix};
    if any(float_WMOs~=deep_offset_tables2.(vtype).(vname).float_WMOs)
        disp('float WMOs do not match')
    else
        for fix = 1:length(float_WMOs)
            this_offset = deep_offset_tables2.(vtype).(vname).deep_offsets(fix);
            if ~isnan(this_offset)
                monthly_bins3.(vtype).(vname)(:,:,fix) = monthly_bins3.(vtype).(vname)(:,:,fix) + this_offset*second_offset_scale_factor;
            end
        end
    end
end

%%

if recalc_third_offsets
    plot_folder3 = [plot_folder 'third_offsets' num2str(max_dist) 'km/'];
    if ~exist(plot_folder3,'dir')
        mkdir(plot_folder3)
    end
    [deep_offset_tables3] = GLOBESINK_deep_bbp_offsets(monthly_bins3,t_edges,zbin_edges,...
        variable_types,variable_names,comparison_depths,float_WMOs,plot_folder3,plot_offset_timeseries,max_dist);
    save([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_third' num2str(max_dist) 'km.mat'],'deep_offset_tables3');
else
    load([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_third' num2str(max_dist) 'km.mat']);
end

%% combine first and second offsets
deep_offset_tables_final = deep_offset_tables;
for vix = 1:length(variable_types)
    vtype = variable_types{vix};
    vname = variable_names{vix};
    deep_offset_tables_final.(vtype).(vname).deep_offsets = ...
        deep_offset_tables.(vtype).(vname).deep_offsets*initial_offset_scale_factor + ...
        deep_offset_tables2.(vtype).(vname).deep_offsets*second_offset_scale_factor;
    if strcmp(vtype,'baseline')
        deep_offset_tables_final.baseline_med.(vname) = deep_offset_tables_final.baseline.(vname);
        deep_offset_tables_final.baseline2.(vname) = deep_offset_tables_final.baseline.(vname);
        deep_offset_tables_final.total.(vname) = deep_offset_tables_final.baseline.(vname);
    end
end

save([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_two_step' num2str(max_dist) 'km.mat'],'deep_offset_tables_final');

%%
writetable(deep_offset_tables_final.baseline.BBP700,[home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_two_step' num2str(max_dist) 'km.csv']);
writetable(deep_offset_tables_final.baseline.BBP700,[home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_two_step' num2str(max_dist) 'km.xlsx']);

% %% test application of combined offsets
% monthly_bins_adjusted = apply_GLOBESINK_deep_offsets(monthly_bins,float_WMOs,deep_offset_tables_final);
% %%
% recalc_third_offsets_again = 1;
% if recalc_third_offsets_again
%     plot_folder4 = [plot_folder 'third_offsets_recalc/'];
%     if ~exist(plot_folder4,'dir')
%         mkdir(plot_folder4)
%     end
%     [deep_offset_tables3_recalc] = GLOBESINK_deep_bbp_offsets(monthly_bins_adjusted,t_edges,zbin_edges,...
%         variable_types,variable_names,comparison_depths,float_WMOs,plot_folder4,plot_offset_timeseries);
%     % save([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_third.mat'],'deep_offset_tables3');
% % else
%     % load([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_third.mat']);
% end
% 
if plot_summary_stats
%% find earliest profile from each float
bio_ix_table_earliest_first = sortrows(bio_ix_table,'mtime','ascend');
[~,uix] = unique(bio_ix_table_earliest_first.float,'first');
bio_ix_table_earliest = bio_ix_table_earliest_first(uix,:);

%%
bio_metadata_ix_table.parameters = bio_ix_table_latest.parameters;

%%


bio_metadata_ix_table_sorted = sortrows(bio_metadata_ix_table,'float');
bio_metadata_ix_table_sorted = bio_metadata_ix_table_sorted(ismember(bio_metadata_ix_table_sorted.float,deep_offset_tables_final.baseline.BBP700.float_WMOs),:);

sensor_types = unique(bio_metadata_ix_table_sorted.BACKSCATTERINGMETER_BBP700_MODEL);
offsets_by_sensor_type = table(sensor_types);

offsets_by_sensor_type.median_offsets = nan(size(sensor_types));
offsets_by_sensor_type.mean_offsets = nan(size(sensor_types));
offsets_by_sensor_type.std_offsets = nan(size(sensor_types));
offsets_by_sensor_type.sterr_offsets = nan(size(sensor_types));
offsets_by_sensor_type.nfloats = nan(size(sensor_types));

figure(221);clf;hold on
for stix = 1:length(sensor_types)
    g = bio_metadata_ix_table_sorted.BACKSCATTERINGMETER_BBP700_MODEL == sensor_types(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    plot(deep_offset_tables_final.baseline.BBP700.deep_offset_ns(g),deep_offset_tables_final.baseline.BBP700.deep_offsets(g),'.')

    offsets_by_sensor_type.median_offsets(stix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_sensor_type.mean_offsets(stix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_sensor_type.std_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_sensor_type.sterr_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
    offsets_by_sensor_type.nfloats(stix) = sum(g);
    
end
legend(rem_(sensor_types))


%%
deployment_years = unique(bio_ix_table_earliest.year);

% offsets_by_sensor_depl_year = table(sensor_types);

offsets_by_sensor_depl_year.median_offsets = nan(length(sensor_types),length(deployment_years));
offsets_by_sensor_depl_year.mean_offsets = nan(length(sensor_types),length(deployment_years));
offsets_by_sensor_depl_year.std_offsets = nan(length(sensor_types),length(deployment_years));
offsets_by_sensor_depl_year.sterr_offsets = nan(length(sensor_types),length(deployment_years));
offsets_by_sensor_depl_year.nfloats = nan(length(sensor_types),length(deployment_years));
for stix = 1:length(sensor_types)
    gs = bio_metadata_ix_table_sorted.BACKSCATTERINGMETER_BBP700_MODEL == sensor_types(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    for yix = 1:length(deployment_years)
        g = gs & bio_ix_table_earliest.year == deployment_years(yix);
        offsets_by_sensor_depl_year.median_offsets(stix,yix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year.mean_offsets(stix,yix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year.std_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year.sterr_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
        offsets_by_sensor_depl_year.nfloats(stix,yix) = sum(g);
    end
end
%%
platform_makers = unique(bio_metadata_ix_table_sorted.PLATFORM_MAKER);
offsets_by_platform_maker = table(platform_makers);

offsets_by_platform_maker.median_offsets = nan(size(platform_makers));
offsets_by_platform_maker.mean_offsets = nan(size(platform_makers));
offsets_by_platform_maker.std_offsets = nan(size(platform_makers));
offsets_by_platform_maker.sterr_offsets = nan(size(platform_makers));
offsets_by_platform_maker.nfloats = nan(size(platform_makers));

figure(222);clf;hold on
for stix = 1:length(platform_makers)
    g = bio_metadata_ix_table_sorted.PLATFORM_MAKER == platform_makers(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    plot(deep_offset_tables_final.baseline.BBP700.deep_offset_ns(g),deep_offset_tables_final.baseline.BBP700.deep_offsets(g),'.')

    offsets_by_platform_maker.median_offsets(stix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_maker.mean_offsets(stix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_maker.std_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_maker.sterr_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
    offsets_by_platform_maker.nfloats(stix) = sum(g);
    
end
legend(rem_(platform_makers))
%%

platform_types = unique(bio_metadata_ix_table_sorted.PLATFORM_TYPE);
offsets_by_platform_type = table(platform_types);

offsets_by_platform_type.median_offsets = nan(size(platform_types));
offsets_by_platform_type.mean_offsets = nan(size(platform_types));
offsets_by_platform_type.std_offsets = nan(size(platform_types));
offsets_by_platform_type.sterr_offsets = nan(size(platform_types));
offsets_by_platform_type.nfloats = nan(size(platform_types));

figure(223);clf;hold on
for stix = 1:length(platform_types)
    g = bio_metadata_ix_table_sorted.PLATFORM_TYPE == platform_types(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    plot(deep_offset_tables_final.baseline.BBP700.deep_offset_ns(g),deep_offset_tables_final.baseline.BBP700.deep_offsets(g),'.')

    offsets_by_platform_type.median_offsets(stix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_type.mean_offsets(stix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_type.std_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
    offsets_by_platform_type.sterr_offsets(stix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
    offsets_by_platform_type.nfloats(stix) = sum(g);
    
end
legend(rem_(platform_types))
%%
offsets_by_platform_depl_year.median_offsets = nan(length(platform_types),length(deployment_years));
offsets_by_platform_depl_year.mean_offsets = nan(length(platform_types),length(deployment_years));
offsets_by_platform_depl_year.std_offsets = nan(length(platform_types),length(deployment_years));
offsets_by_platform_depl_year.sterr_offsets = nan(length(platform_types),length(deployment_years));
offsets_by_platform_depl_year.nfloats = nan(length(platform_types),length(deployment_years));
for stix = 1:length(platform_types)
    gs = bio_metadata_ix_table_sorted.PLATFORM_TYPE == platform_types(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    for yix = 1:length(deployment_years)
        g = gs & bio_ix_table_earliest.year == deployment_years(yix);
        offsets_by_platform_depl_year.median_offsets(stix,yix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_platform_depl_year.mean_offsets(stix,yix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_platform_depl_year.std_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_platform_depl_year.sterr_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
        offsets_by_platform_depl_year.nfloats(stix,yix) = sum(g);
    end
end

%% plot deep offsets
figure(220);clf;hold on
plot([-8e-4 8e-4],[-8e-4 8e-4],'k')
for stix = 1:length(sensor_types)
    g = bio_metadata_ix_table_sorted.BACKSCATTERINGMETER_BBP700_MODEL == sensor_types(stix);
    plot(deep_offset_tables.baseline.BBP700.deep_offsets(g),deep_offset_tables_final.baseline.BBP700.deep_offsets(g),'.')
end
plot_linearfit_II(deep_offset_tables.baseline.BBP700.deep_offsets,deep_offset_tables_final.baseline.BBP700.deep_offsets);
legend(rem_(sensor_types),'location','southeast')
%%
% Convert categorical to string for sorting
[~, sortIdx] = sort(string(offsets_by_sensor_type.sensor_types));  % Or: sort(cellstr(T.Name))
offsets_by_sensor_type = offsets_by_sensor_type(sortIdx,:);
sort_again_Idx = [2 8 9 3:7 10:13 1];
offsets_by_sensor_type = offsets_by_sensor_type(sort_again_Idx,:);

offsets_by_sensor_type = offsets_by_sensor_type(offsets_by_sensor_type.nfloats>1,:);

main_sensor_ixs_sorted = find(offsets_by_sensor_type.nfloats>50);
%%
% Convert categorical to string for sorting
[~, sortIdx] = sort(string(offsets_by_platform_type.platform_types));  % Or: sort(cellstr(T.Name))
offsets_by_platform_type = offsets_by_platform_type(sortIdx,:);
% sort_again_Idx = [2 8 9 3:7 10:13 1];
% offsets_by_platform_type = offsets_by_platform_type(sort_again_Idx,:);

offsets_by_platform_type = offsets_by_platform_type(offsets_by_platform_type.nfloats>1,:);
%%

figure(321);clf;hold on
bar(-offsets_by_sensor_type.mean_offsets)
% errorbar(1:height(offsets_by_sensor_type),offsets_by_sensor_type.mean_offsets,offsets_by_sensor_type.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
errorbar(1:height(offsets_by_sensor_type),-offsets_by_sensor_type.mean_offsets,offsets_by_sensor_type.sterr_offsets*2,'k','linestyle','none')
plot(1:height(offsets_by_sensor_type),-offsets_by_sensor_type.median_offsets,'ro')
set(gca,'xtick',1:height(offsets_by_sensor_type),'xticklabel',rem_(offsets_by_sensor_type.sensor_types))
ylabel('deep BBP700 offsets relative to nearby sensors (m^-^1)')
title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
ylim([-1e-4 0.5e-4])
legend('mean','±2*sterr','median','location','southeast')
set(gcf,'paperunits','inches','papersize',[8 5],'paperposition',[0 0 8 5])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_sensor_all' num2str(max_dist) 'km.png'])    
%%
offsets_by_sensor_type_main = offsets_by_sensor_type(main_sensor_ixs_sorted,:);
figure(1321);clf;hold on
bar(-offsets_by_sensor_type_main.mean_offsets)
% errorbar(1:height(offsets_by_sensor_type_main),offsets_by_sensor_type_main.mean_offsets,offsets_by_sensor_type_main.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
errorbar(1:height(offsets_by_sensor_type_main),-offsets_by_sensor_type_main.mean_offsets,offsets_by_sensor_type_main.sterr_offsets*2,'k','linestyle','none')
plot(1:height(offsets_by_sensor_type_main),-offsets_by_sensor_type_main.median_offsets,'ro')
set(gca,'xtick',1:height(offsets_by_sensor_type_main),'xticklabel',rem_(offsets_by_sensor_type_main.sensor_types))
ylabel('deep BBP700 offsets relative to nearby sensors (m^-^1)')
title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
legend('mean','±2*sterr','median')
set(gcf,'paperunits','inches','papersize',[8 5],'paperposition',[0 0 8 5])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_sensor_major' num2str(max_dist) 'km.png'])    
%%
main_sensor_ixs = sensor_types([1 2 3 11]);
figure(2321);clf;
for ii = 1:length(main_sensor_ixs)
    sensor_ix = main_sensor_ixs(ii);
    subplot(2,2,ii);hold on
    bar(-offsets_by_sensor_depl_year.mean_offsets(sensor_ix,:))
    % errorbar(1:height(offsets_by_sensor_depl_year),offsets_by_sensor_depl_year.mean_offsets,offsets_by_sensor_depl_year.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
    errorbar(1:length(deployment_years),-offsets_by_sensor_depl_year.mean_offsets(sensor_ix,:),offsets_by_sensor_depl_year.sterr_offsets(sensor_ix,:)*2,'k','linestyle','none')
    plot(1:length(deployment_years),-offsets_by_sensor_depl_year.median_offsets(sensor_ix,:),'ro')
    set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
    ylabel('deep BBP700 offsets (m^-^1)')
    % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
    ylim([-1e-4 1e-4])
    title(rem_(sensor_types(sensor_ix)))
    if ii == 1
    legend('mean','±2*sterr','median')
    end
end
set(gcf,'paperunits','inches','papersize',[12 8],'paperposition',[0 0 12 8])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_sensor_and_deploy_year' num2str(max_dist) 'km.png'])
%%
main_sensor_ixs = sensor_types([1:4 6:end]);
figure(3421);clf;
for ii = 1:length(main_sensor_ixs)
    sensor_ix = main_sensor_ixs(ii);
    subplot(3,4,ii);hold on
    bar(-offsets_by_sensor_depl_year.mean_offsets(sensor_ix,:))
    % errorbar(1:height(offsets_by_sensor_depl_year),offsets_by_sensor_depl_year.mean_offsets,offsets_by_sensor_depl_year.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
    errorbar(1:length(deployment_years),-offsets_by_sensor_depl_year.mean_offsets(sensor_ix,:),offsets_by_sensor_depl_year.sterr_offsets(sensor_ix,:)*2,'k','linestyle','none')
    plot(1:length(deployment_years),-offsets_by_sensor_depl_year.median_offsets(sensor_ix,:),'ro')
    set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
    ylabel('deep BBP700 offsets (m^-^1)')
    % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
    ylim([-1e-4 1e-4])
    title(rem_(sensor_types(sensor_ix)))
    if ii == 1
    legend('mean','±2*sterr','median')
    end
end
set(gcf,'paperunits','inches','papersize',[12 8],'paperposition',[0 0 12 8])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_sensor_and_deploy_year_all' num2str(max_dist) 'km.png'])
%%
main_platform_types = platform_types([1:5 7:end]); % platform_types([1:4 8:end-1]);

figure(2322);clf;
for ii = 1:length(main_platform_types)
    platform_type = main_platform_types(ii);
    platform_ix = find(platform_types==platform_type,1);
    subplot(3,4,ii);hold on
    bar(-offsets_by_platform_depl_year.mean_offsets(platform_ix,:))
    % errorbar(1:height(offsets_by_platform_depl_year),offsets_by_platform_depl_year.mean_offsets,offsets_by_platform_depl_year.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
    errorbar(1:length(deployment_years),-offsets_by_platform_depl_year.mean_offsets(platform_ix,:),offsets_by_platform_depl_year.sterr_offsets(platform_ix,:)*2,'k','linestyle','none')
    plot(1:length(deployment_years),-offsets_by_platform_depl_year.median_offsets(platform_ix,:),'ro')
    set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
    ylabel('deep BBP700 offsets (m^-^1)')
    % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
    ylim([-1e-4 1e-4])
    title(rem_(platform_types(platform_ix)))
    if ii == 1
    legend('mean','±2*sterr','median','location','southwest')
    end
end
set(gcf,'paperunits','inches','papersize',[12 8],'paperposition',[0 0 12 8])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_platform_and_deploy_year' num2str(max_dist) 'km.png'])

%%

figure(322);clf;hold on
bar(-offsets_by_platform_maker.mean_offsets)
% errorbar(1:height(offsets_by_platform_maker),offsets_by_platform_maker.mean_offsets,offsets_by_platform_maker.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
errorbar(1:height(offsets_by_platform_maker),-offsets_by_platform_maker.mean_offsets,offsets_by_platform_maker.sterr_offsets*2,'k','linestyle','none')
plot(1:height(offsets_by_platform_maker),-offsets_by_platform_maker.median_offsets,'ro')
set(gca,'xtick',1:height(offsets_by_platform_maker),'xticklabel',rem_(offsets_by_platform_maker.platform_makers))
ylabel('deep BBP700 offsets (m^-^1)')
title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])

%%

figure(323);clf;hold on
bar(-offsets_by_platform_type.mean_offsets)
% errorbar(1:height(offsets_by_platform_type),offsets_by_platform_type.mean_offsets,offsets_by_platform_type.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
errorbar(1:height(offsets_by_platform_type),-offsets_by_platform_type.mean_offsets,offsets_by_platform_type.sterr_offsets*2,'k','linestyle','none')
plot(1:height(offsets_by_platform_type),-offsets_by_platform_type.median_offsets,'ro')
set(gca,'xtick',1:height(offsets_by_platform_type),'xticklabel',rem_(offsets_by_platform_type.platform_types))
ylabel('deep BBP700 offsets (m^-^1)')
title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
set(gcf,'paperunits','inches','papersize',[12 8],'paperposition',[0 0 12 8])
print('-dpng',[plot_folder 'deep_bbp_offsets_by_float_model' num2str(max_dist) 'km.png'])
%%
is_CTS4_floats = ismember(bio_metadata_ix_table_sorted.PLATFORM_TYPE,categorical({'PROVOR_III','PROVOR_III_JUMBO'}));
is_solo_floats = ismember(bio_metadata_ix_table_sorted.PLATFORM_TYPE,categorical({'SOLO_BGC_MRV','SOLO_II','SOLO_BGC'}));
solo_WMOs = bio_metadata_ix_table_sorted.float(is_solo_floats);

solo_bio_ix = bio_ix_table_earliest(ismember(bio_ix_table_earliest.float,solo_WMOs),:);
solo_float_metadata = bio_metadata_ix_table_sorted(is_solo_floats,:);
solo_float_metadata = sortrows(solo_float_metadata,"float");

CTS4_float_metadata = bio_metadata_ix_table_sorted(is_CTS4_floats,:);

%%
%% single sensor offsets by platform
for six = 1:length(sensor_types)
    sensor_type = sensor_types(six);
    sensor_name = char(sensor_type);
    sensor_name(sensor_name==' ') = '_';
    offsets_platform_year.(sensor_name).median_offsets = nan(length(platform_types),length(deployment_years));
    offsets_platform_year.(sensor_name).mean_offsets = nan(length(platform_types),length(deployment_years));
    offsets_platform_year.(sensor_name).std_offsets = nan(length(platform_types),length(deployment_years));
    offsets_platform_year.(sensor_name).sterr_offsets = nan(length(platform_types),length(deployment_years));
    offsets_platform_year.(sensor_name).nfloats = nan(length(platform_types),length(deployment_years));
    for stix = 1:length(platform_types)
        gs = bio_metadata_ix_table_sorted.BACKSCATTERINGMETER_BBP700_MODEL == sensor_type & bio_metadata_ix_table_sorted.PLATFORM_TYPE == platform_types(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
        for yix = 1:length(deployment_years)
            g = gs & bio_ix_table_earliest.year == deployment_years(yix);
            offsets_platform_year.(sensor_name).median_offsets(stix,yix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).mean_offsets(stix,yix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).std_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).sterr_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
            offsets_platform_year.(sensor_name).nfloats(stix,yix) = sum(g);
            if sum(g) == 1
                offsets_platform_year.(sensor_name).sterr_offsets(stix,yix) = 1;
            end
        end
    end
    %%
    % main_platform_ixs = platform_types([1:5 7:end]); % platform_types([1:4 8:end-1]);
    % figure(1010);clf;
    % for ii = 1:length(main_platform_ixs)
    %     platform_ix = main_platform_ixs(ii);

    main_platform_types = platform_types([1:5 7:end]); % platform_types([1:4 8:end-1]);

    figure(2322);clf;
    for ii = 1:length(main_platform_types)
        platform_type = main_platform_types(ii);
        platform_ix = find(platform_types==platform_type,1);
        subplot(3,4,ii);hold on
        bar(-offsets_platform_year.(sensor_name).mean_offsets(platform_ix,:))
        % errorbar(1:height(offsets_platform_year.(sensor_name)),offsets_platform_year.(sensor_name).mean_offsets,offsets_platform_year.(sensor_name).std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
        errorbar(1:length(deployment_years),-offsets_platform_year.(sensor_name).mean_offsets(platform_ix,:),offsets_platform_year.(sensor_name).sterr_offsets(platform_ix,:)*2,'k','linestyle','none')
        plot(1:length(deployment_years),-offsets_platform_year.(sensor_name).median_offsets(platform_ix,:),'ro')
        set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
        ylabel('deep BBP700 offsets (m^-^1)')
        % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
        ylim([-1e-4 1e-4])
        title([rem_(sensor_name) '-' rem_(platform_types(platform_ix))])
        if ii == 1
            legend('mean','±2*sterr','median','location','southwest')
        end
    end
    set(gcf,'paperunits','inches','papersize',[15 10],'paperposition',[0 0 15 10])
    print('-dpng',[plot_folder 'deep_bbp_offsets_by_platform_and_deploy_year_' sensor_name '_' num2str(max_dist) 'km.png'])
end

%% condensed tables
bmt2 = bio_metadata_ix_table_sorted;
bmt2.BACKSCATTERINGMETER_BBP700_MODEL(ismember(bmt2.BACKSCATTERINGMETER_BBP700_MODEL,...
    categorical({'ECO_FLBB_2K','ECO_FLBB_AP2','ECO_FLBB'}))) = categorical({'ECO_FLBB'});
bmt2.BACKSCATTERINGMETER_BBP700_MODEL(ismember(bmt2.BACKSCATTERINGMETER_BBP700_MODEL,...
    categorical({'ECO_FLBBCD','ECO_FLBB2','ECO_FLBBFL','ECO_FLBBCD_AP2','ECO_FLBBFL_AP2'}))) = categorical({'ECO_Triplet'});
bmt2.BACKSCATTERINGMETER_BBP700_MODEL(ismember(bmt2.BACKSCATTERINGMETER_BBP700_MODEL,...
    categorical({'MCOMS_FLBBCD','MCOMS_FLBB2'}))) = categorical({'MCOMS'});

bmt2.PLATFORM_TYPE(ismember(bmt2.PLATFORM_TYPE,...
    categorical({'NAVIS_A','NAVIS_EBR'}))) = categorical({'NAVIS'});
bmt2.PLATFORM_TYPE(ismember(bmt2.PLATFORM_TYPE,...
    categorical({'PROVOR_III','PROVOR_III_JUMBO'}))) = categorical({'CTS4'});
bmt2.PLATFORM_TYPE(ismember(bmt2.PLATFORM_TYPE,...
    categorical({'PROVOR_V','PROVOR_V_JUMBO'}))) = categorical({'CTS5'});
bmt2.PLATFORM_TYPE(ismember(bmt2.PLATFORM_TYPE,...
    categorical({'SOLO_BGC','SOLO_II','SOLO_BGC_MRV'}))) = categorical({'SOLO'});

% bmt2.BACKSCATTERINGMETER_BBP700_MODEL(ismember(bmt2.PLATFORM_TYPE,...
%     categorical({'SOLO_BGC_MRV'}))&ismember(bmt2.BACKSCATTERINGMETER_BBP700_MODEL,...
%     categorical({'UNKNOWN'}))) = categorical({'ECO_Triplet'});

%% single sensor offsets by platform
sensors_condensed = unique(bmt2.BACKSCATTERINGMETER_BBP700_MODEL);
platforms_condensed = unique(bmt2.PLATFORM_TYPE);
for six = 1:length(sensors_condensed)
    sensor_type = sensors_condensed(six);
    sensor_name = char(sensor_type);
    sensor_name(sensor_name==' ') = '_';
    offsets_platform_year.(sensor_name).median_offsets = nan(length(platforms_condensed),length(deployment_years));
    offsets_platform_year.(sensor_name).mean_offsets = nan(length(platforms_condensed),length(deployment_years));
    offsets_platform_year.(sensor_name).std_offsets = nan(length(platforms_condensed),length(deployment_years));
    offsets_platform_year.(sensor_name).sterr_offsets = nan(length(platforms_condensed),length(deployment_years));
    offsets_platform_year.(sensor_name).nfloats = nan(length(platforms_condensed),length(deployment_years));
    for stix = 1:length(platforms_condensed)
        gs = bmt2.BACKSCATTERINGMETER_BBP700_MODEL == sensor_type & bmt2.PLATFORM_TYPE == platforms_condensed(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
        for yix = 1:length(deployment_years)
            g = gs & bio_ix_table_earliest.year == deployment_years(yix);
            offsets_platform_year.(sensor_name).median_offsets(stix,yix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).mean_offsets(stix,yix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).std_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
            offsets_platform_year.(sensor_name).sterr_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
            offsets_platform_year.(sensor_name).nfloats(stix,yix) = sum(g);
            if sum(g) < 3
                offsets_platform_year.(sensor_name).sterr_offsets(stix,yix) = 1;
            end
        end
    end
    %%
    % main_platform_ixs = platforms_condensed([1:5 7:end]); % platforms_condensed([1:4 8:end-1]);
    % figure(1010);clf;
    % for ii = 1:length(main_platform_ixs)
    %     platform_ix = main_platform_ixs(ii);

    main_platforms_condensed = platforms_condensed([1 6:end]); % platforms_condensed([1:4 8:end-1]);

    figure(2322);clf;
    for ii = 1:length(main_platforms_condensed)
        platform_type = main_platforms_condensed(ii);
        platform_ix = find(platforms_condensed==platform_type,1);
        subplot(2,2,ii);hold on
        bar(-offsets_platform_year.(sensor_name).mean_offsets(platform_ix,:))
        % errorbar(1:height(offsets_platform_year.(sensor_name)),offsets_platform_year.(sensor_name).mean_offsets,offsets_platform_year.(sensor_name).std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
        errorbar(1:length(deployment_years),-offsets_platform_year.(sensor_name).mean_offsets(platform_ix,:),offsets_platform_year.(sensor_name).sterr_offsets(platform_ix,:)*2,'k','linestyle','none')
        plot(1:length(deployment_years),-offsets_platform_year.(sensor_name).median_offsets(platform_ix,:),'ro')
        set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
        ylabel('deep BBP700 offsets (m^-^1)')
        % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
        ylim([-1e-4 1e-4])
        title([rem_(sensor_name) '-' rem_(platforms_condensed(platform_ix))])
        if ii == 1
            legend('mean','±2*sterr','median','location','southwest')
        end
    end
    set(gcf,'paperunits','inches','papersize',[15 10],'paperposition',[0 0 15 10])
    print('-dpng',[plot_folder 'deep_bbp_offsets_condensed_by_platform_and_deploy_year_' sensor_name '_' num2str(max_dist) 'km.png'])
end
%%
%%
deployment_years = unique(bio_ix_table_earliest.year);

% offsets_by_sensor_depl_year = table(sensor_types);

offsets_by_sensor_depl_year2.median_offsets = nan(length(sensors_condensed),length(deployment_years));
offsets_by_sensor_depl_year2.mean_offsets = nan(length(sensors_condensed),length(deployment_years));
offsets_by_sensor_depl_year2.std_offsets = nan(length(sensors_condensed),length(deployment_years));
offsets_by_sensor_depl_year2.sterr_offsets = nan(length(sensors_condensed),length(deployment_years));
offsets_by_sensor_depl_year2.nfloats = nan(length(sensors_condensed),length(deployment_years));

for stix = 1:length(sensors_condensed)
    gs = bmt2.BACKSCATTERINGMETER_BBP700_MODEL == sensors_condensed(stix)&~isnan(deep_offset_tables_final.baseline.BBP700.deep_offsets);
    for yix = 1:length(deployment_years)
        g = gs & bio_ix_table_earliest.year == deployment_years(yix);
        offsets_by_sensor_depl_year2.median_offsets(stix,yix) = nanmedian(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year2.mean_offsets(stix,yix) = nanmean(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year2.std_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g));
        offsets_by_sensor_depl_year2.sterr_offsets(stix,yix) = nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets(g))/sqrt(sum(g));
        offsets_by_sensor_depl_year2.nfloats(stix,yix) = sum(g);
    end
end

%%
main_sensors_condensed = sensors_condensed([3 5 6]);
figure(3421);clf;
for ii = 1:length(main_sensors_condensed)
    this_sensor = main_sensors_condensed(ii);
    sensor_ix = find(sensors_condensed==this_sensor);
    subplot(3,1,ii);hold on
    bar(-offsets_by_sensor_depl_year2.mean_offsets(sensor_ix,:))
    % errorbar(1:height(offsets_by_sensor_depl_year2),offsets_by_sensor_depl_year2.mean_offsets,offsets_by_sensor_depl_year2.std_offsets,'color',[0.6 0.6 0.6],'linestyle','none')
    errorbar(1:length(deployment_years),-offsets_by_sensor_depl_year2.mean_offsets(sensor_ix,:),offsets_by_sensor_depl_year2.sterr_offsets(sensor_ix,:)*2,'k','linestyle','none')
    plot(1:length(deployment_years),-offsets_by_sensor_depl_year2.median_offsets(sensor_ix,:),'ro')
    set(gca,'xtick',1:length(deployment_years),'xticklabel',num2str(deployment_years))
    ylabel('deep BBP700 offsets (m^-^1)')
    % title(['std offset all: ' num2str(nanstd(deep_offset_tables_final.baseline.BBP700.deep_offsets))])
    ylim([-1e-4 1e-4])
    title(rem_(sensors_condensed(sensor_ix)))
    if ii == 1
    legend('mean','±2*sterr','median')
    end
end
set(gcf,'paperunits','inches','papersize',[8 12],'paperposition',[0 0 8 12])
print('-dpng',[plot_folder 'deep_bbp_offsets_condensed_by_sensor_and_deploy_year_all' num2str(max_dist) 'km.png'])
end