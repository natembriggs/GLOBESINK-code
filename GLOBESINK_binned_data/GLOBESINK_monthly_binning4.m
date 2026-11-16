% GLOBESINK_monthly_binning4.m
% This script is used for creating monthly bins and plotting the data for Biogeochemical Argo floats.

clear
% Set up folders and load data
download_home = home_folder; % Home folder path
[BGC_Argo_data_folder,BGC_Argo_plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home); % Function to get folders

bathmat = load_global_bathymetry(); % Load global bathymetry data

% Set up file and variable names
mat_file_folder = [download_home 'BiogeochemicalArgo/single_float_data_mat_format/'];
datafile_name = 'GLOBESINK_global_2025'; % Name of the file
    % version_text = 'beta20250611';
    version_text = 'beta20260401';
% datafile_name = 'GLOBESINK_global'; % Name of the file
%     version_text = 'beta20241206_newbin';
    % version_text = 'beta20241206';
    % version_text = 'beta20240904';
    % version_text = 'beta20240212';

% load([GLOBESINK_data_folder 'float_WMOs_' datafile_name '.mat']) % Load float WMOs
load([GLOBESINK_data_folder 'BGC_Argo_data_' datafile_name '_metadata.mat'])
load([GLOBESINK_data_folder 'BGC_Argo_data_' datafile_name '_bin_opts.mat'])
float_WMOs = bio_ix_table_latest.float;

% key_import_variables = {'PRES','TEMP','PSAL','BBP700','CHLA'}; % Key variables to import
% optional_variables = {'DOXY','NITRATE','CP660','BBP700_2','BBP532','BBP470','CDOM'}; % Optional variables
percast_vnames = {'LATITUDE','LONGITUDE','M_TIME'}; % Names of variables per cast
vars_to_bin = bin_opts.vars_to_bin;%[GLOBESINK_opts.key_import_variables GLOBESINK_opts.optional_variables]; % All variables to bin
vars_to_filter = bin_opts.vars_to_filter;

% Set up binning parameters
% t_edges = datenum(2010,1:(12*14+3),1); % Time bin edges
zbin_edges = bin_opts.zbin_edges; % Depth bin edges in meters

switch datafile_name 
    case 'GLOBESINK_global_2025'
        t_edges = datenum(2010,1:(12*15+6),1); % Time bin edges
    otherwise
        t_edges = datenum(2010,1:(12*14+9),1); % Time bin edges
end
ntbins = length(t_edges)-1; % Number of time bins
nfloats = length(float_WMOs); % Number of floats
zbin_mids = midpoints(zbin_edges)'; % Middle of depth bins
nzbins = length(zbin_mids); % Number of depth bins


recalc_monthly_bins = 1; % Flag to recalculate monthly per-float bins
add_deep_bbp_offsets = 1;

exclude_near_shelf = 1;
apply_manual_QC = 1; 
apply_auto_QC = 1;
remove_FDOM_spikes = 0;
remove_bbp_spike_clusters = 0;

recalc_monthly_maps = 1; % Flag to recalculate monthly climatologies
lat_interval = 4; lon_interval = 8;
% lat_interval = 3; lon_interval = 3;

recalc_yearly_monthly_maps = 1; % Flag to recalculate monthly maps, separated by year

recalc_martin_curves = 0;
    replot_martin_curves = 1;
% martin_curve_fit_ixs = 5:20; % 150-975
martin_curve_fit_ixs = 4:20; % 100-975

deep_align_text = ''; if add_deep_bbp_offsets; deep_align_text = '_deep_aligned'; end
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
% QC_text = 'auto_baseline_QC_only';

% Initialize and calculate monthly bins
if recalc_monthly_bins
    [monthly_bins] = GLOBESINK_monthly_perfloat_bins(t_edges,bin_opts,float_WMOs,...
        percast_vnames,mat_file_folder,exclude_near_shelf,QC_text);
    %
    save([GLOBESINK_data_folder 'BGC_Argo_monthly_bins_' datafile_name '_' version_text shelf_text QC_text '.mat'],'monthly_bins','zbin_edges','t_edges','float_WMOs','bin_opts','-v7.3')
else
    load([GLOBESINK_data_folder 'BGC_Argo_monthly_bins_' datafile_name '_' version_text shelf_text QC_text '.mat'])
    % load([data_folder 'BGC_Argo_monthly_bins_' datafile_name '.mat'])
end
%
if add_deep_bbp_offsets
    load([home_folder 'BiogeochemicalArgo/data/GLOBESINK_QC_data/GLOBESINK_float_deep_offsets_two_step2000km.mat']);
    % %% test application of combined offsets
    monthly_bins = apply_GLOBESINK_deep_offsets(monthly_bins,float_WMOs,deep_offset_tables_final);
    save([GLOBESINK_data_folder 'BGC_Argo_monthly_bins_' datafile_name deep_align_text '_' version_text shelf_text QC_text '.mat'],'monthly_bins','zbin_edges','t_edges','float_WMOs','bin_opts','-v7.3')
end
%% find bbr (deprecated)
zmids = midpoints(bin_opts.zbin_edges);
min_bbp = squeeze(min(monthly_bins.baseline2.BBP700,[],2));
med_bbp = squeeze(nanmedian(monthly_bins.baseline2.BBP700,2));
med_lat = squeeze(nanmedian(monthly_bins.LATITUDE,2))';

% [min_min_bbp,minix] = min(min_bbp,1);

med_bbr_profile = nanmedian(min_bbp,2);
bbr_ref_ix = 18;
bbr_by_float = (min_bbp(bbr_ref_ix,:)+med_bbr_profile(end)-med_bbr_profile(bbr_ref_ix))';
bbr_mat = repmat(bbr_by_float',length(zmids),1);

% min_bbp = min_bbp - bbr_mat;
% med_bbp = med_bbp - bbr_mat;
%%
figure(13+add_deep_bbp_offsets);clf;
subplot(1,2,1);hold on        
plot3c(min_bbp,repmat(zmids,1,length(med_lat)),repmat(med_lat,length(zmids),1),'.');axis ij
plot(nanmedian(min_bbp,2),zmids,'k');axis ij
plot(quantile(min_bbp,0.1,2),zmids,'k');axis ij
plot(quantile(min_bbp,0.9,2),zmids,'k');axis ij
xlim([-0.0001 0.001])
title(['deep aligned = ' num2str(add_deep_bbp_offsets)])
xlabel('min monthly bbp per float')
cbarlabel('lat');
subplot(1,2,2);hold on        
plot3c(med_bbp,repmat(zmids,1,length(med_lat)),repmat(med_lat,length(zmids),1),'.');axis ij
plot(nanmedian(med_bbp,2),zmids,'k');axis ij
plot(quantile(med_bbp,0.1,2),zmids,'k');axis ij
plot(quantile(med_bbp,0.9,2),zmids,'k');axis ij
xlim([-0.0001 0.001])
title(['deep aligned = ' num2str(add_deep_bbp_offsets)])
xlabel('median monthly bbp per float')
cbarlabel('lat');
%% test plots

% Test plots
% (These blocks create various scatter plots of the processed data)
load coastlines.mat
%%
mstart_ix = 6:12:size(monthly_bins.LONGITUDE,2);
x = monthly_bins.LONGITUDE(:,mstart_ix,:);
y = monthly_bins.LATITUDE(:,mstart_ix,:);
s1 = sqrt(monthly_bins.nfilt.CHLA(2,mstart_ix,:));
cc = monthly_bins.baseline.CHLA(2,mstart_ix,:);
% x = monthly_bins.LONGITUDE;
% y = monthly_bins.LATITUDE;
% s1 = sqrt(monthly_bins.nfilt.CHLA(3,:,:));
% cc = monthly_bins.baseline.CHLA(3,:,:);
g1 = s1>sqrt(20);
figure(30);clf;hold on
plot(coastlon,coastlat,'k');
scatter(x(g1),y(g1),s1(g1)+10,cc(g1),'filled');
cbarlabel('Chl');
caxis([0 2]);
%%
% x = monthly_bins.LONGITUDE;
% y = monthly_bins.LATITUDE;
% s1 = sqrt(monthly_bins.nfilt.BBP700(2,:,:));
% c0 = monthly_bins.baseline.BBP700(2,:,:)*35000;
s1 = sqrt(monthly_bins.nfilt.BBP700(2,mstart_ix,:));
c0 = monthly_bins.baseline.BBP700(2,mstart_ix,:)*35000;
g1 = s1>sqrt(100);
figure(40);clf;hold on
plot(coastlon,coastlat,'k');
scatter(x(g1),y(g1),s1(g1)+10,c0(g1),'filled');
cbarlabel('POC');
caxis([0 200])
%%
% x = monthly_bins.LONGITUDE;
% y = monthly_bins.LATITUDE;
s1 = sqrt(monthly_bins.nfilt.BBP700(2,mstart_ix,:));
cy = monthly_bins.D_mean_nobig.BBP700(2,mstart_ix,:);
g1 = s1>sqrt(10);
figure(50);clf;hold on
plot(coastlon,coastlat,'k');
scatter(x(g1),y(g1),s1(g1)+10,cy(g1),'filled');
cbarlabel('size');
caxis([0 200])
%%
% x = monthly_bins.LONGITUDE;
% y = monthly_bins.LATITUDE;
s2 = sqrt(mean(monthly_bins.nfilt.BBP700(6:8,mstart_ix,:),1));
cx = mean(monthly_bins.spikes.BBP700(6:8,mstart_ix,:),1)*35000*75;
g2 = s2>sqrt(100);
figure(60);clf;hold on
plot(coastlon,coastlat,'k');
scatter(x(g2),y(g2),s2(g2)+10,cx(g2),'filled');
cbarlabel('export');
caxis([0 300])
%%
g = g1&g2;
figure(70);clf;hold on
scatter(log10(cy(g)),log10(cx(g)),(s1(g)+s2(g))/2,y(g),'filled');
plot_linearfit_II(log10(cy(g)),log10(cx(g)));
cbarlabel('lat');
xlabel('D mean'); ylabel('export')
%%
g = g1&g2;
figure(80);clf;hold on
scatter(log10(c0(g)),log10(cx(g)),(s1(g)+s2(g))/2,y(g),'filled')
plot_linearfit_II(log10(c0(g)),log10(cx(g)));
xlabel('POC'); ylabel('export')
%%
g = g1&g2;
figure(81);clf;hold on
scatter(log10(c0(g).*cy(g)),log10(cx(g)),(s1(g)+s2(g))/2,y(g),'filled')
plot_linearfit_II(log10(c0(g).*cy(g)),log10(cx(g)));
% plot_linearfit_II_weighted(log10(c0(g).*c1(g)),log10(c2(g)),s1(g).^2,s2(g).^2);
xlabel('POC*D mean'); ylabel('export')
%%

figure(90);clf;hold on
scatter(log10(c0(g1)),log10(cy(g1)),s1(g1),y(g1),'filled')
xlabel('log_1_0 POC'); ylabel('log_1_0 D mean')
cbarlabel('lat');

%% AVERAGE INTO SPATIAL GRID (MONTHLY MAPS)
% (This section bins the float data into regular spatial grid cells by month)

% if is_hires
%     lat_interval = 1; %
%     lon_interval = 2; %
%     res_text = '_hires';
% else
%     lat_interval = 4; % 1; %
%     lon_interval = 8; % 2; %
%     res_text = '';
% end

if recalc_monthly_maps

    [monthly_maps,lat_edges,lon_edges] = GLOBESINK_monthly_climatology_maps(monthly_bins,t_edges,lat_interval,lon_interval,bin_opts);

    save([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],...
        'monthly_maps','zbin_edges','lat_edges','t_edges','lon_edges','bin_opts','-v7.3')

    % [monthly_maps_median,lat_edges,lon_edges] = GLOBESINK_monthly_climatology_maps_median(monthly_bins,t_edges,lat_interval,lon_interval);
    % save([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_median_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],...
    %     'monthly_maps_median','zbin_edges','lat_edges','t_edges','lon_edges','bin_opts','-v7.3')
else
    if exist([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '_fluxes.mat'],'file')
        load([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '_fluxes.mat'])
        monthly_maps.nfilt.POC_total = monthly_maps.nfilt.BBP700;
        monthly_maps.nfilt.POC_l = monthly_maps.nfilt.BBP700;
        monthly_maps.nfilt.POC_s = monthly_maps.nfilt.BBP700;
    else
        load([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'])
    end
    % load([data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '.mat'])
end
%%
if recalc_monthly_maps && recalc_monthly_bins
    %% apply bbr to monthly bins
    lat_midpoints = midpoints(lat_edges); lon_midpoints = midpoints(lon_edges);
    bbr = squeeze(monthly_maps.baseline2_refractory.BBP700(1,:,:,1));
    [xmat, ymat] = meshgrid(1:size(bbr, 2), 1:size(bbr, 1));
    g = ~isnan(bbr);
    bbr_interp = griddata(xmat(g), ymat(g), bbr(g),xmat,ymat, 'nearest');
    % reshape(c,1,length(lat_midpoints),length(lon_midpoints),1);
    monthly_bins.baseline2_refractory.BBP700 = nan(size(monthly_bins.baseline2.BBP700));
    latixs = interp1(lat_midpoints',1:length(lat_midpoints),monthly_bins.LATITUDE,'nearest','extrap');
    lonixs = interp1(lon_midpoints',1:length(lon_midpoints),monthly_bins.LONGITUDE,'nearest','extrap');
    % latixs(isnan(latixs)) = 1; lonixs(isnan(lonixs)) = 1;
    % tmp = monthly_maps.baseline2_refractory.BBP700(1,latixs,lonixs,1);
    % monthly_bins.baseline2_refractory.BBP700 = monthly_maps.baseline2_refractory(1,latixs,lonixs);
    for tix = 1:size(monthly_bins.baseline2_refractory.BBP700,2)
        for fix = 1:size(monthly_bins.baseline2_refractory.BBP700,3)
            latix = latixs(1,tix,fix);
            lonix = lonixs(1,tix,fix);
            if ~isnan(latix) && ~isnan(lonix)
                % monthly_bins.baseline2_refractory.BBP700(:,tix,fix) = monthly_maps.baseline2_refractory.BBP700(1,latix,lonix,1);
                monthly_bins.baseline2_refractory.BBP700(:,tix,fix) = bbr_interp(latix,lonix);
            end
        end
    end
    monthly_bins.baseline2_labile.BBP700 = max(monthly_bins.baseline2.BBP700 - monthly_bins.baseline2_refractory.BBP700,0);
    monthly_bins.baseline2_labile.BBP700(isnan(monthly_bins.baseline2.BBP700)) = nan;
    n_neg_labile = sum(sum(monthly_bins.baseline2_labile.BBP700(1,:,:)<0));
    %%
    save([GLOBESINK_data_folder 'BGC_Argo_monthly_bins_' datafile_name deep_align_text '_' version_text shelf_text QC_text '.mat'],'monthly_bins','zbin_edges','t_edges','float_WMOs','bin_opts','-v7.3')
    
end

mmap = length(lat_edges)-1; nmap = length(lon_edges)-1;
lat_mids = midpoints(lat_edges); lon_mids = midpoints(lon_edges);

%% AVERAGE INTO YEARLY RESOLVED SPATIAL GRID (YEARLY MONTHLY MAPS)
% (This section bins the float data into regular spatial grid cells by month)


if recalc_yearly_monthly_maps
    [yearly_monthly_maps,lat_edges,lon_edges,map_years] = GLOBESINK_yearly_monthly_maps(monthly_bins,t_edges,lat_interval,lon_interval);
    save([GLOBESINK_data_folder 'BGC_Argo_yearly_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],...
        'yearly_monthly_maps','zbin_edges','lat_edges','t_edges','lon_edges','map_years','bin_opts','-v7.3')
    % save([data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_test_hires.mat'],'monthly_maps','zbin_edges','lat_edges','lon_edges','-v7.3')
elseif exist([GLOBESINK_data_folder 'BGC_Argo_yearly_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '_fluxes.mat'],'file')
    load([GLOBESINK_data_folder 'BGC_Argo_yearly_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '_fluxes.mat'])
    yearly_monthly_maps.nfilt.POC_total = yearly_monthly_maps.nfilt.BBP700;
    yearly_monthly_maps.nfilt.POC_l = yearly_monthly_maps.nfilt.BBP700;
    yearly_monthly_maps.nfilt.POC_s = yearly_monthly_maps.nfilt.BBP700;
elseif exist([GLOBESINK_data_folder 'BGC_Argo_yearly_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],'file')
    load([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'])
    % load([data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '.mat'])
end

if exist('map_years','var')
    mmap = length(lat_edges)-1; nmap = length(lon_edges)-1;
    lat_mids = midpoints(lat_edges); lon_mids = midpoints(lon_edges);
    nyears = length(map_years);
end
%%
%%
% Fit Martin curves
% (This section fits Martin curves to the export fluxes vs. depth)%%
% recalc_martin_curves = 1;
%     replot_martin_curves = 1;
% martin_curve_fit_ixs = 5:20; % 150-975
martin_curve_z_text = [num2str(zbin_edges(martin_curve_fit_ixs(1))) '-' ...
    num2str(zbin_edges(martin_curve_fit_ixs(end)+1))];

if recalc_martin_curves
disp(['calculating martin curves between ' martin_curve_z_text ' m'])
martin_bs = nan(1,mmap,nmap,12);
martin_bints = nan(2,mmap,nmap,12);
martin_as = nan(1,mmap,nmap,12);
martin_aints = nan(2,mmap,nmap,12);
martin_rmses = nan(1,mmap,nmap,12);
martin_r2s = nan(1,mmap,nmap,12);
vtypes = {'spikes','spikes2'};
for vtix = 1:length(vtypes)
vtype = vtypes{vtix};
monthly_maps.([vtype '_smooth_Martin']).BBP700 = nan(size(monthly_maps.(vtype).BBP700));
monthly_maps.([vtype '_smooth_Martin']).BBP700_upper = nan(size(monthly_maps.(vtype).BBP700));
monthly_maps.([vtype '_smooth_Martin']).BBP700_lower = nan(size(monthly_maps.(vtype).BBP700));
monthly_maps.(vtype).BBP700_upper = nan(size(monthly_maps.(vtype).BBP700));
monthly_maps.(vtype).BBP700_lower = nan(size(monthly_maps.(vtype).BBP700));
z = zbin_mids(martin_curve_fit_ixs);
for latix = 1:length(lat_edges)-1
    if replot_martin_curves
        figure(19);clf;hold on
    end
    for mix = 1:12
        if replot_martin_curves
            subplot(3,4,mix);hold on
        end
        for lonix = 1:length(lon_edges)-1
        % v = monthly_maps.spikes.BBP700(martin_curve_fit_ixs,latix,lonix,mix)*35000*75;
        v = monthly_maps.(vtype).BBP700(martin_curve_fit_ixs,latix,lonix,mix);
        if sum(~isnan(v))>12
%             n = monthly_maps.nfilt.BBP700(martin_curve_fit_ixs,latix,lonix,mix);
            if replot_martin_curves
                plot(v,z,'*');axis ij
                [h_l, h_t, cf_,gof] = plot_martin_curve(v,z);axis ij
                title(datestr(datenum(1,mix,1),'mmm'))
                set(h_t,'string','')
            else
                [cf_,gof] = get_martin_curve(v,z);
            end
            martin_as(1,latix,lonix,mix) = cf_.a;
            martin_bs(1,latix,lonix,mix) = cf_.b;
            cint = confint(cf_);
            martin_bints(:,latix,lonix,mix) = cint(:,2);
            martin_aints(:,latix,lonix,mix) = cint(:,2);
            martin_r2s(1,latix,lonix,mix) = gof.rsquare;
            martin_rmses(1,latix,lonix,mix) = gof.rmse;

            monthly_maps.([vtype '_smooth_Martin']).BBP700(martin_curve_fit_ixs,latix,lonix,mix) = cf_(z/100);
            ci = predint(cf_,z/100,0.95,'functional','off');
            monthly_maps.([vtype '_smooth_Martin']).BBP700_upper(martin_curve_fit_ixs,latix,lonix,mix) = ci(:,2);
            monthly_maps.([vtype '_smooth_Martin']).BBP700_lower(martin_curve_fit_ixs,latix,lonix,mix) = ci(:,1);
            ci = predint(cf_,z/100,0.95,'observation','off');
            monthly_maps.(vtype).BBP700_upper(martin_curve_fit_ixs,latix,lonix,mix) = ci(:,2);
            monthly_maps.(vtype).BBP700_lower(martin_curve_fit_ixs,latix,lonix,mix) = ci(:,1);
        end
        end
    end
    if replot_martin_curves
        set(gcf,'paperunits','inches','papersize',[20 15],'paperposition',[0 0 20 15])
        print('-dpng',[BGC_Argo_plot_folder 'GLOBESINK_martin_curves/Martin_curves_' vtype '_lat' num2str(lat_edges(latix)) '_' ...
            num2str(lat_edges(latix+1)) '.png'])
    end
end
end
    save([GLOBESINK_data_folder 'BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],...
        'monthly_maps','zbin_edges','lat_edges','t_edges','lon_edges','bin_opts','-v7.3')
    save([GLOBESINK_data_folder 'BGC_Argo_Martin_curve_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],'martin_bs','martin_bints','martin_as','martin_aints','martin_rmses','martin_r2s','lat_edges','lon_edges')
elseif exist([GLOBESINK_data_folder 'BGC_Argo_Martin_curve_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'],'file')
    load([GLOBESINK_data_folder 'BGC_Argo_Martin_curve_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '.mat'])
    
end
%%
% monthly_maps.baseline2.CHLA_BBP700_ratio = monthly_maps.baseline2.CHLA./monthly_maps.baseline2.BBP700;
% monthly_maps.nfilt.CHLA_BBP700_ratio = monthly_maps.nfilt.BBP700;
% monthly_maps.baseline2.CHLA_ADJUSTED_BBP700_ratio = monthly_maps.baseline2.CHLA_ADJUSTED./monthly_maps.baseline2.BBP700;
% monthly_maps.nfilt.CHLA_ADJUSTED_BBP700_ratio = monthly_maps.nfilt.BBP700;
%%
load(['BGC_Argo_monthly_maps_' datafile_name deep_align_text '_' version_text shelf_text QC_text res_text '_fluxes_interpolated.mat']) 

%%
shallow_ixs = 2;
DCM_ixs = 4:5;
export_ixs = 5:7;
% export_ixs = 12:20;
meso_ixs = 10:14;
deep_ixs = 18:20;
z_ixs = {shallow_ixs,export_ixs,meso_ixs,deep_ixs,DCM_ixs};
for ii = 1:length(z_ixs)
    depth_texts{ii} = [' ' num2str(zbin_edges(z_ixs{ii}(1))) '-' num2str(zbin_edges(z_ixs{ii}(end)+1)) ' m'];
end
% depth_texts = {[' ' num2str(zbin_edges(shallow_ixs(1))) '-' num2str(zbin_edges(shallow_ixs(end)+1)) ' m'],...
%     [' ' num2str(zbin_edges(export_ixs(1))) '-' num2str(zbin_edges(export_ixs(end)+1)) ' m'],...
%     [' ' num2str(zbin_edges(meso_ixs(1))) '-' num2str(zbin_edges(meso_ixs(end)+1)) ' m']};
% meso_ixs = 15:20;
min_n = 10;
% min_n = 50;
% min_n = 200;
plot_cbarlabels = 1;

bath_struct = load_global_bathymetry;
n_text = ['_n' num2str(min_n)];
y = lat_edges;x = lon_edges;


%
% vnames = {'BBP700','CHLA','BBP700','BBP700','BBP700','CHLA_BBP700_ratio','BBP700','BBP700','BBP700','BBP700','BBP700','BBP700','BBP700'};
% % vtypes = {'baseline','baseline','D_mean_nobig','spikes_med','spikes_med','baseline','spikes_smooth_Martin','spikes_smooth_Martin'};
% vtypes = {'baseline','baseline','D_mean_nobig','spikes','spikes','baseline','spikes_smooth_Martin','spikes_smooth_Martin','spikes_big','spikes_big','spikes_small','spikes_small','D_mean'};
% multipliers = [35000,1,1,35000*75,35000*75,1,35000*75,35000*75,35000*75,35000*75,35000*75,35000*75, 1];
% vlims = [0 200; 0 2; 0 150; 0 200; 0 200; 0 1500; 0 200; 0 200; 0 200; 0 200; 0 200; 0 200; 0 150];
% map_names = {'POC','CHL','size','export','meso_flux','CHL_bbp','export_smoothed','meso_smoothed','big_export','big_meso','small_export','small_meso','size_all'};
% longnames = {'POC_{bb} (m^-^1)','Chl a (mg m^-^3)','D_{mean} (µm)',...
%     'POC flux (mg m^-^2 d^-^1)','POC flux (mg m^-^2 d^-^1)','Chl/b_b_p (mg m^-^2)',...
%     'POC flux smoothed (mg m^-^2 d^-^1)','POC flux smoothed (mg m^-^2 d^-^1)',...
%     'POC flux big (mg m^-^2 d^-^1)','POC flux big (mg m^-^2 d^-^1)',...
%     'POC flux small (mg m^-^2 d^-^1)','POC flux small (mg m^-^2 d^-^1)','D_{mean} all (µm)'};
% depth_ixs = [1 1 1 2 3 1 2 3 2 3 2 3 1];
% map_plot_table = table(map_names',vnames',vtypes',multipliers',vlims,depth_ixs',longnames');
% map_plot_table.Properties.VariableNames = {'map_names','vnames','vtypes','multipliers','vlims','depth_ixs','longnames'};
% writetable(map_plot_table,[mat_file_folder 'GLOBESINK_map_plot_table.xlsx'])
%
mpt = readtable([mat_file_folder 'GLOBESINK_map_plot_table.xlsx']);
clear sph
for plot_ix = 1:length(mpt.vnames)
    vtype = mpt.vtypes{plot_ix};
    vname = mpt.vnames{plot_ix};
    figure(199); clf;
    % figure(199+plot_ix); clf;
    set(gcf, 'InvertHardcopy', 'off');
    set(gcf,'color','w')
    for mix = 1:12
        % try subplot(sph(mix,plot_ix))
        % catch
        %     sph(mix,plot_ix) = subplot(3,4,mix);hold on
        % end
        % % plot(coastlon,coastlat,'k')
        % % plot_global_bathymetry_land_mask;

        sph(mix,plot_ix) = subplot(3,4,mix);hold on
        title(datestr(datenum(1,mix,1),'mmm'))
        c = squeeze(nanmean(monthly_maps.(vtype).(vname)(z_ixs{mpt.depth_ixs(plot_ix)},:,:,mix),1)*mpt.multipliers(plot_ix));
        if strcmp(vtype,'total')
            n = squeeze(nansum(monthly_maps.n.(vname)(z_ixs{mpt.depth_ixs(plot_ix)},:,:,mix),1));
        else
            n = squeeze(nansum(monthly_maps.nfilt.(vname)(z_ixs{mpt.depth_ixs(plot_ix)},:,:,mix),1));
        end
        if ~strcmp(vtype,'nfilt')&&~strcmp(vtype,'n')
            c(n<min_n) = nan;
        end
        interp_maps = 1;
            use_saved_interpolations = 1;
        if interp_maps
            if use_saved_interpolations
                c = squeeze(nanmean(monthly_maps_interpolated.(vtype).(vname)(z_ixs{mpt.depth_ixs(plot_ix)},:,:,mix),1)*mpt.multipliers(plot_ix));
            else
                [cm,cn] = size(c);
                lon_window = round(24/lon_interval/2)*2-1;
                lat_window = round(12/lat_interval/2)*2-1;
                c_extended = c(:,[ceil(cn*2/3):cn 1:cn 1:floor(cn/3)]);
                n_extended = running_sum_2D(~isnan(c_extended),lat_window,lon_window);
                c_extended = running_nanmedian_2D(c_extended,lat_window,lon_window);
                c_extended(n_extended<3) = nan;
                [xmat, ymat] = meshgrid(1:size(c, 2), 1:size(c, 1));
                [xmat_extended, ymat_extended] = meshgrid(1:size(c_extended, 2), 1:size(c_extended, 1));
                xmat_extended = xmat_extended-length(ceil(cn*2/3):cn);
                g = ~isnan(c_extended);
                c_interp = griddata(xmat_extended(g), ymat_extended(g), c_extended(g),xmat,ymat, 'linear');
                % c = c_extended(:,length(ceil(cn*2/3):cn)+(1:cn));
                c_interp(repmat(midpoints(y)',1,length(x)-1)<-66 & isnan(c)) = nan;
                c = c_interp;
            end
        end
        n(end+1,:) = 0; n(:,end+1) = 0; c(end+1,:) = nan; c(:,end+1) = nan;

        % pcolor(x,y,c_interp);shading flat
        pcolor(x,y,c);shading flat
        clim([mpt.vlims_1(plot_ix,:) mpt.vlims_2(plot_ix,:)])
        if ~interp_maps
            plot(coastlon,coastlat,'k')
        end
        switch mpt.map_names{plot_ix}
            case {'size','size_DCM','size_all_DCM','size_all','CHL_bbp','CHL_bbp_total_night','CHL_bbp_DCM'}
            case {'CHL','CHL_DCM','CHL_export','CHL_export2','CHL_meso','CHL_meso2',...
                    'CHL_adjusted_total','CHL_adjusted_total_night','CHL_total','CHL_total_night'}
                set_cmap_green_pale_dark_bright;
            otherwise
                set_cmap_red_pale_dark_bright;
        end
        set(gca,'color',[0.5 0.5 0.5],'xtick',[],'ytick',[])
        xlim([-180 180]);ylim([-90 90])
    end
    if plot_cbarlabels
        subplot(sph(8,plot_ix))
        ax_position = get(gca,'position');
        cbarlabel([mpt.longnames{plot_ix} depth_texts{mpt.depth_ixs(plot_ix)}]);% 'meso flux smoothed ' num2str(zbin_edges(meso_ixs(1))) '-' num2str(zbin_edges(meso_ixs(end)+1)) ' m']);
        set(gca,'position',ax_position)
    end
    subplot(sph(10,plot_ix))
    xlabel(rem_([QC_text shelf_text res_text n_text]))
    if interp_maps
        [~,hc1] = contourf(sph(1,plot_ix),bath_struct.x,bath_struct.y,bath_struct.z,[-1000 0],'facecolor','w','edgecolor','none');
        [~,hc2] = contourf(sph(1,plot_ix),bath_struct.x,bath_struct.y,bath_struct.z,[0 1],'facecolor','k');
        for mix = 2:12
            copyobj(hc1,sph(mix,plot_ix))
            copyobj(hc2,sph(mix,plot_ix))
        end
    end
    if interp_maps; interp_text = '_interpolated'; else; interp_text = ''; end
    set(gcf,'paperunits','inches','papersize',[20 12]/2,'paperposition',[0 0 20 12]/2)
    print('-dpng',[BGC_Argo_plot_folder 'GLOBESINK_maps/' mpt.map_names{plot_ix} QC_text shelf_text res_text n_text interp_text '_' version_text '.png'])
    if ~interp_maps
        print('-dpdf','-vector',[BGC_Argo_plot_folder 'GLOBESINK_maps/pdfs/' mpt.map_names{plot_ix} QC_text shelf_text res_text n_text interp_text '_' version_text '.pdf'])
    end
    % print('-dpdf','-vector',[BGC_Argo_plot_folder 'GLOBESINK_maps/' map_names{plot_ix} QC_text shelf_text res_text n_text '.pdf'])

end
%%


%%
shallow_ixs = 2;
shallow_depth_text = [num2str(zbin_edges(shallow_ixs(1))) '-' num2str(zbin_edges(shallow_ixs(end)+1)) ' m'];
% export_ixs = 5:7;
% export_ixs = 8:11;
export_ixs = 12:20;
export_depth_text = [num2str(zbin_edges(export_ixs(1))) '-' num2str(zbin_edges(export_ixs(end)+1)) ' m'];
% export_ixs = 12:20;
meso_ixs = 10:14;
% meso_ixs = 15:20;

x6 = squeeze(mean(monthly_maps.total.TEMP(export_ixs,:,:,:),1));
x5 = squeeze(mean(monthly_maps.total.TEMP(shallow_ixs,:,:,:),1));
x4 = squeeze(mean(max(monthly_maps.total.CHLA(shallow_ixs,:,:,:),0.01),1));
x1 = squeeze(mean(monthly_maps.D_mean_nobig.BBP700(shallow_ixs,:,:,:),1));
x2 = squeeze(mean(monthly_maps.baseline.BBP700(shallow_ixs,:,:,:),1))*35000;
x3 = x1.*x2;%squeeze(mean(monthly_maps.D_mean_nobig.BBP700(shallow_ixs,:,:,:),1).^1.*mean(monthly_maps.baseline.BBP700(shallow_ixs,:,:,:),1));
xn = squeeze(monthly_maps.nfilt.BBP700(shallow_ixs(1),:,:,:));
y = squeeze(mean(monthly_maps.spikes.BBP700(export_ixs,:,:,:),1)*35000*75);
y = y + squeeze(mean(monthly_maps.baseline.BBP700(export_ixs,:,:,:),1)*35000*0.5);
yn = squeeze(monthly_maps.nfilt.BBP700(export_ixs(1),:,:,:));
c = repmat(midpoints(lat_edges)',size(x1,2),size(x1,3));
min_n = 40;
g = yn>min_n&xn>min_n;

figure(300);clf;hold on
scatter(log10(x1(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
[h_l,h_t] = plot_linearfit_II(log10(x1(g)),log10(y(g)));
set(h_t(1),'string','')
% plot_linearfit(log10(x1(g)),log10(y(g)));
xlabel('log_1_0 mean D (µm)')
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])
% cbarlabel('lat');
%
figure(301);clf;hold on
scatter(log10(x2(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
[h_l,h_t] = plot_linearfit_II(log10(x2(g)),log10(y(g)));
set(h_t(1),'string','')
% plot_linearfit(log10(x2(g)),log10(y(g)));

xlabel('log_1_0 surf POC')
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])
%

figure(302);clf;hold on
scatter(log10(x3(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
[h_l,h_t] = plot_linearfit_II(log10(x3(g)),log10(y(g)));
% set(h_t(1),'string','')
% plot_linearfit(log10(x3(g)),log10(y(g)));
xlabel('log_1_0 POC * mean D (µm)')
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])

% Prints current figure to pdf on Desktop

%
figure(303);clf;hold on
scatter(log10(x4(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
[h_l,h_t] = plot_linearfit_II(log10(x4(g)),log10(y(g)));
set(h_t(1),'string','')
% plot_linearfit(log10(x3(g)),log10(y(g)));
xlabel('log_1_0 Chl (mg m^-^3)')
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])
%
figure(304);clf;hold on
scatter((x5(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
% [h_l,h_t] = plot_linearfit((x5(g)),log10(y(g)));
% set(h_t([1 3]),'string','')
% plot_linearfit(log10(x3(g)),log10(y(g)));
xlabel('surface T (°C)')
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])

figure(305);clf;hold on
scatter((x6(g)),log10(y(g)),sqrt(sqrt(xn(g).*yn(g))),c(g))
% [h_l,h_t] = plot_linearfit((x6(g)),log10(y(g)));
% set(h_t([1 3]),'string','')
% plot_linearfit(log10(x3(g)),log10(y(g)));
xlabel(['subsurface T ' export_depth_text ' (°C)'])
ylabel(['log_1_0 POC flux ' export_depth_text ' mg/m^-^2 d^-^1'])
%
xnames = {'D_mean','POC','POCxD','Chl','Tsurf','Tdeep'};
for ii = 1:6
    figure(299+ii);
    set(gcf,'paperunits','inches','papersize',[5 5],'paperposition',[0 0 5 5])
    plot_folder = [home_folder 'BiogeochemicalArgo/plots/GLOBESINK_flux_validation/' version_text QC_text '/flux_surface_predictors/'];
    if ~exist(plot_folder,'dir')
        mkdir(plot_folder)
    end
    print('-dpng',[plot_folder xnames{ii} shallow_depth_text(1:end-2) '_flux' export_depth_text(1:end-2) 'm.png'])
end
%%
figure(2204);clf;hold on
figure(2205);clf;hold on
for mix = 1:12
    y = lat_edges;x = lon_edges;
    cy = squeeze(nanmean(monthly_maps.spikes.BBP700(export_ixs,:,:,mix),1)*35000*75)+...
        squeeze(nanmean(monthly_maps.baseline.BBP700(export_ixs,:,:,mix),1)*35000*0.5);
    cx = squeeze(nanmean(monthly_maps.baseline.BBP700(shallow_ixs,:,:,mix),1)*35000).*...
        squeeze(nanmean(monthly_maps.D_mean_nobig.BBP700(shallow_ixs,:,:,mix),1));
    cy(cy<=0) = nan; cx(cx<0)=nan;
    % c = log10(cy)-(log10(cx)*1.02-1.59); 
    % c = log10(cy)-(log10(cx)*0.896-1.22); 
    c = log10(cy)-(log10(cx)*0.796-1.1); 
    c(end+1,:) = nan; c(:,end+1) = nan;
    n = squeeze(sum(monthly_maps.nfilt.BBP700(export_ixs,:,:,mix),1)); n(end+1,:) = 0; n(:,end+1) = 0;
    c(n<min_n) = nan;
    export_anomalies(:,:,mix) = c;
    figure(2204)
    subplot(3,4,mix);hold on
    title(datestr(datenum(1,mix,1),'mmm'))
    pcolor(x,y,c);shading flat
    plot(coastlon,coastlat,'k')
    xlim([-180 180]);ylim([-90 90])
    caxis([-1 1])
    set_cmap_plus_minus_hires;
    set(gca,'color',[0.5 0.5 0.5],'xtick',[],'ytick',[])
%     axis off
    figure(2205)
    subplot(3,4,mix);hold on
    title(datestr(datenum(1,mix,1),'mmm'))
    sx = log10(cx); sy = log10(cy); ss = n(1:end-1,1:end-1); sc = repmat(lat_mids',1,length(lon_mids));
    g = ~isnan(sx+sy+ss+sc);
    scatter(sx(g),sy(g),sqrt(ss(g)),sc(g));
    plot([1.5 4.5],[1.5 4.5]*0.897-1.23,'k')
    xlim([1.5 4.5])
    ylim([0 3])
end
if plot_cbarlabels
    figure(2204)
    cbarlabel(['export flux anomaly']);
end
%%
figure(2206);clf;hold on
nnotnan = sum(~isnan(export_anomalies),3);
medanon= nanmedian(export_anomalies,3);
medanon(nnotnan<3) = nan;
    pcolor(x,y,medanon);shading flat
    plot(coastlon,coastlat,'k')
    xlim([-180 180]);ylim([-90 90])
    clim([-1 1]);
    cbarlabel('export anomalies');
    set_cmap_plus_minus_hires;
    set(gca,'color',[0.75 0.75 0.75],'xtick',[],'ytick',[])


%%
upper_ixs = 4:6;
mid_ixs = 7:11;
lower_ixs = 12:20;
bbp_blank = 1.9e-4;%0;%
frag_proxy_mid = squeeze(mean(monthly_maps.baseline.BBP700(mid_ixs,:,:,:)-bbp_blank,1)./mean(monthly_maps.spikes.BBP700(meso_ixs,:,:,:),1))*0.1;
f_upper = squeeze(median(monthly_maps.spikes.BBP700(upper_ixs,:,:,:),1))*35000*75;
f_mid = squeeze(median(monthly_maps.spikes.BBP700(mid_ixs,:,:,:),1))*35000*75;
f_lower = squeeze(median(monthly_maps.spikes.BBP700(lower_ixs,:,:,:),1))*35000*75;
n_upper = squeeze(sum(monthly_maps.nfilt.BBP700(upper_ixs,:,:,:),1));
n_mid = squeeze(sum(monthly_maps.nfilt.BBP700(mid_ixs,:,:,:),1));
n_lower = squeeze(sum(monthly_maps.nfilt.BBP700(lower_ixs,:,:,:),1));
Teff = f_lower./f_upper;
T_mid = squeeze(mean(monthly_maps.total.TEMP(mid_ixs,:,:,:),1));
O2_mid = squeeze(mean(monthly_maps.total.DOXY(mid_ixs,:,:,:),1));

g = n_lower>100&f_mid>50;

figure(600);clf;hold on
plot3c(f_upper(g),f_lower(g),frag_proxy_mid(g),'.');
figure(601);clf;hold on
plot(frag_proxy_mid(g),1./Teff(g),'.')
figure(602);clf;hold on
plot(f_mid(g),1./Teff(g),'.')

%%
figure(1204);clf;hold on
for mix = 1:12
    subplot(3,4,mix);hold on
    title(datestr(datenum(1,mix,1),'mmm'))
    y = lat_edges;x = lon_edges;
    c = squeeze(martin_as(:,:,:,mix)); c(end+1,:) = nan; c(:,end+1) = nan;
    cint = squeeze(diff(martin_aints(:,:,:,mix),1,1)); cint(end+1,:) = nan; cint(:,end+1) = nan;
    n = squeeze(monthly_maps.nfilt.BBP700(export_ixs(1),:,:,mix)); n(end+1,:) = 0; n(:,end+1) = 0;
%     c(n<min_n) = nan;
    c(cint>50) = nan;
    pcolor(x,y,c);shading flat
    plot(coastlon,coastlat,'k')
    xlim([-180 180]);ylim([-90 90])
    % clim([0 500]/40000/75)
    set_cmap_red_pale_dark_bright;
%     set(gca,'color',[0.5 0.5 0.5],'xtick',[],'ytick',[])
%     axis off
end
if plot_cbarlabels
    cbarlabel('flux');
end
%%
figure(2204);clf;hold on
for mix = 1:12
    subplot(3,4,mix);hold on
    title(datestr(datenum(1,mix,1),'mmm'))
    y = lat_edges;x = lon_edges;
    c = -squeeze(martin_bs(:,:,:,mix)); c(end+1,:) = nan; c(:,end+1) = nan;
    cint = squeeze(diff(martin_bints(:,:,:,mix),1,1)); cint(end+1,:) = nan; cint(:,end+1) = nan;
    n = squeeze(monthly_maps.nfilt.BBP700(export_ixs(1),:,:,mix)); n(end+1,:) = 0; n(:,end+1) = 0;
%     c(n<min_n) = nan;
    c(cint>2) = nan;
    pcolor(x,y,c);shading flat
    plot(coastlon,coastlat,'k')
    xlim([-180 180]);ylim([-90 90])
    clim([0 2])
    % clim([0 500]/40000/75)
    set_cmap_red_pale_dark_bright;
%     set(gca,'color',[0.5 0.5 0.5],'xtick',[],'ytick',[])
%     axis off
end
if plot_cbarlabels
    cbarlabel('b');
end
%%
bbp_blank = 1.9e-4;%0;%0;%
% frag_proxy = squeeze(mean(monthly_maps.baseline.BBP700(meso_ixs,:,:,:)-bbp_blank,1)./mean(monthly_maps.spikes.BBP700(meso_ixs,:,:,:),1))*0.1;
frag_proxy = squeeze(mean(monthly_maps.baseline.BBP700(mid_ixs,:,:,:)-bbp_blank,1)./mean(monthly_maps.spikes.BBP700(mid_ixs,:,:,:),1))*0.1;
% frag_proxy = squeeze(mean(monthly_maps.baseline.BBP700(meso_ixs,:,:,:)-bbp_blank,1));
T = squeeze(mean(monthly_maps.total.TEMP(meso_ixs,:,:,:),1));
O2 = squeeze(mean(monthly_maps.total.DOXY(meso_ixs,:,:,:),1));
bs = squeeze(martin_bs);
as = squeeze(martin_as)*75*35000;
f200 = as.*2.^bs;
% f200 = squeeze(median(monthly_maps.spikes.BBP700(6,:,:,:),1))*35000*75;
bints = squeeze(martin_bints(2,:,:,:)-martin_bints(1,:,:,:));
gbs = bints<1.4;%&squeeze(martin_rmses)<100;
% gbs = bints<0.9;
gbs = gbs&as<1500;%/35000/75;
min_f200 = 100;%/35000/75;
gbs = gbs&f200>min_f200;%&squeeze(martin_rmses)<100;
% gbs = gbs&f200>20;%&squeeze(martin_rmses)<100;
% gbs = gbs&f_upper_meso>90;%&squeeze(martin_rmses)<100;
%
figure(400);clf;hold on
subplot(2,2,1);hold on
% plot3c(T(gbs),-bs(gbs),f200(gbs),'*');
scatter(T(gbs),-bs(gbs),f200(gbs),f200(gbs));
plot_linearfit(T(gbs),-bs(gbs));
xlabel('T');ylabel('flux attenuation exponent')

%
gO2 = gbs & is_between(O2,0,400);
subplot(2,2,2);hold on
scatter(O2(gO2),-bs(gO2),f200(gO2),f200(gO2))
% plot3c(O2(gO2),-bs(gO2),f200(gO2),'.')
plot_linearfit(O2(gO2),-bs(gO2));
xlabel('O_2 (µmol kg^-^1)');ylabel('flux attenuation exponent')

%
subplot(2,2,3);hold on
% scatter(frag_proxy(gbs),-bs(gbs),10./bints(gbs))
scatter(frag_proxy(gbs),-bs(gbs),f200(gbs),f200(gbs));
% plot3c(frag_proxy(gbs),-bs(gbs),f200(gbs),'.');
plot_linearfit(frag_proxy(gbs),-bs(gbs));
xlabel('fragmentation proxy');ylabel('flux attenuation exponent')
%
subplot(2,2,4);hold on
% scatter(frag_proxy(gbs),-bs(gbs),10./bints(gbs))
% plot3c(f_upper_meso(gbs),-bs(gbs),f200(gbs),'.')
scatter(f200(gbs),-bs(gbs),f200(gbs),f200(gbs))
% plot3c(f200(gbs),-bs(gbs),f200(gbs),'.')
plot_linearfit(f200(gbs),-bs(gbs));
xlabel('200 m flux');ylabel('flux attenuation exponent')
% Prints current figure to pdf on Desktop

set(gcf,'paperunits','inches','papersize',[12 10],'paperposition',[0 0 12 10])
    print('-dpng',['~/Desktop/b_drivers_f200_' num2str(min_f200) '.png'])        

%%
v = nanmean(nanmean(monthly_maps.spikes.BBP700,3),4)*35000*75;
z_ixs = 6:20;%length(zbin_mids);
figure(500);clf;hold on
for latix = 1:nmap
    hc = plot3c(v(z_ixs,latix),zbin_mids(z_ixs),ones(size(zbin_mids(z_ixs)))*lat_mids(latix));
    axis ij
end
cbarlabel('lat');
