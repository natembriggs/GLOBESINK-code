% GLOBESINK_POC_flux_calculation_v2.m

clear
%%
add_medium_size_class = 1;

run_monthly_maps = 1;
run_yearly_monthly_maps = 0;
run_monthly_bins = 1;
%
flux_metadata.POC_bbp_ratio = 31700; % reanalysis of Cetinic at 100 m (POC/bbp700 = -114z + 43098; POC_bbp700_vs_depth_NAB08_top_100_GLOBESINK.png)
flux_metadata.POC_bbp_ratio_upper = flux_metadata.POC_bbp_ratio * 58968/35422; % (53607*1.1); % reanalysis of Cetinic at 100 m, adjusted for Stramski et al., 2008 upwelling excluded
% flux_metadata.POC_bbp_ratio_upper = 58968; % (53607*1.1); % Stramski et al., 2008 upwelling excluded
% flux_metadata.POC_bbp_ratio = 42893; % Geometric mean of lower and upper limits
% flux_metadata.POC_bbp_ratio = 35422; % Cetinic
% flux_metadata.POC_bbp_ratio_lower = 31200; % Johnson et al. (2017)
flux_metadata.POC_bbp_ratio_lower = flux_metadata.POC_bbp_ratio * 31200/35422; % reanalysis of Cetinic at 100 m, adjusted for Johnson
flux_metadata.w_l = 74; % m/d (Briggs et al., 2020)
flux_metadata.w_l_upper = 100; % m/d (Briggs et al., 2020)
flux_metadata.w_l_lower = 58; % m/d (Briggs et al., 2020)
if add_medium_size_class
    flux_metadata.w_m = flux_metadata.w_l*0.5^.63; % Cael et al. (2021) adjustment of w_l
    flux_metadata.w_m_upper = flux_metadata.w_l_upper*0.5^.63; % Cael et al. (2021) adjustment of w_l
    flux_metadata.w_m_lower = flux_metadata.w_l_lower*0.5^.63; % Cael et al. (2021) adjustment of w_l
    % flux_metadata.w_m = 35; % 
    POC_size_suffices = {'_l','_m','_s'};
    POC_size_names = {'large','medium','small'};
    % bbp_size_vtypes = {'spikes_medium2','spikes_small2','baseline2'};
    bbp_size_vtypes = {'spikes_medium2','spikes_small2','baseline2_labile'};
else
    POC_size_suffices = {'_l','_s'};
    POC_size_names = {'large','small'};
    % bbp_size_vtypes = {'spikes2','baseline2'};
    bbp_size_vtypes = {'spikes2','baseline2_labile'};
end
flux_metadata.w_s = 2.5;
flux_metadata.w_s_upper = 5;
flux_metadata.w_s_lower = 0;

flux_metadata.POC_bbp_zcorrect_slope_top100 = 0.0036; % (m^-1) 114/317000
flux_metadata.POC_l_bbp_zcorrect_exponent = -0.45; % Mouw et al. (2016) POC/mass flux below 90 m
% flux_metadata.POC_l_bbp_zcorrect_exponent = -0.28;

if add_medium_size_class
    flux_metadata.POC_m_bbp_zcorrect_exponent = -0.45;%-0.63;%-0.28;
end

flux_metadata.POC_s_bbp_zcorrect_exponent = -0.45; %-0.83; %-0.54*0.43/0.28 %-0.54;%-0.28;

flux_metadata.units.POC_bbp_ratio = 'mg m^-^2 d^-^1'; % cetinic
flux_metadata.units.POC_bbp_zcorrect_slope_top100 = 'm^-^1';

for six = 1:length(POC_size_suffices)
    flux_metadata.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent_lower']) = flux_metadata.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent'])*1.5;
    flux_metadata.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent_upper']) = flux_metadata.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent'])*0.5;

    flux_metadata.units.(['w' POC_size_suffices{six}]) = 'm d^-^1'; % m/d
    flux_metadata.units.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent']) = ''; % unitless
end

% flux_metadata.units.w_l = 'm d^-^1'; % m/d
% if add_medium_size_class
%     flux_metadata.units.w_m = 'm d^-^1';
% end
% flux_metadata.units.w_s = 'm d^-^1';
% flux_metadata.units.POC_l_bbp_zcorrect_exponent = '';
% if add_medium_size_class
%     flux_metadata.units.POC_m_bbp_zcorrect_exponent = 'm d^-^1';
% end
% flux_metadata.units.POC_s_bbp_zcorrect_exponent = '';%-0.28;

flux_metadata.descriptions.POC_bbp_ratio = 'ratio used to convert bbp to POC at 100 m'; % cetinic
if add_medium_size_class
    flux_metadata.descriptions.w_l = 'large-particle (>~400 µm) sinking speed'; % m/d
    flux_metadata.descriptions.w_m = 'medium-particle (~200-400 µm) sinking speed'; % m/d
else
    flux_metadata.descriptions.w_l = 'large-particle (>~200 µm) sinking speed'; % m/d
end
flux_metadata.descriptions.w_s = 'small-particle (<~200 µm) sinking speed';
flux_metadata.descriptions.POC_bbp_zcorrect_slope_top100 = 'slope m used to convert large-particle bbp to POC above 100 m: POC_bbp(z)=POC_bbp(100m)*(1+(100-z)*m)';
for six = 1:length(POC_size_suffices)
    flux_metadata.descriptions.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent']) = ...
        ['power law exponent b used to convert ' POC_size_names{six} '-particle bbp to POC below 100 m: POC_bbp(z)=POC_bbp(100m)*(z/100)^(b)'];
end
% flux_metadata.descriptions.POC_l_bbp_zcorrect_exponent = 'power law exponent b used to convert large-particle bbp to POC below 100 m: POC_bbp(z)=POC_bbp(100m)*(z/100)^(b)';
% if add_medium_size_class
%     flux_metadata.descriptions.POC_m_bbp_zcorrect_exponent = 'power law exponent b used to convert medium-particle bbp to POC below 100 m: POC_bbp(z)=POC_bbp(100m)*(z/100)^(b)';
% end
% flux_metadata.descriptions.POC_s_bbp_zcorrect_exponent = 'power law exponent b used to convert small-particle bbp to POC below 100 m: POC_bbp(z)=POC_bbp(100m)*(z/100)^(b)';
%%
download_home = home_folder; % Home folder path
[BGC_Argo_data_folder,BGC_Argo_plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home); % Function to get folders

% dataset_name = 'GLOBESINK_global_2025'; % Name of the file
dataset_name = 'GLOBESINK_global_2025_deep_aligned'; % Name of the file
    % datafile_suffix = 'beta20250611';
    % datafile_suffix = 'beta20260211';
    datafile_suffix = 'beta20260401';

    % dataset_name = 'GLOBESINK_global'; % Name of the file
%     datafile_suffix = 'beta20241206_newbin';

% datafile_name = 'BGC_Argo_monthly_maps_GLOBESINK_global_test';
datafile_name = ['BGC_Argo_monthly_maps_' dataset_name];
datafile_name2 = ['BGC_Argo_monthly_bins_' dataset_name];
datafile_name3 = ['BGC_Argo_yearly_monthly_maps_' dataset_name];
% datafile_suffix = 'beta20240212_not_cleaned';
% datafile_suffix = 'beta20240212_no_manual_QC';
% datafile_suffix = 'beta20240212_no_auto_QC';
% datafile_suffix = 'beta20240212';
% datafile_suffix = 'beta20240212auto_baseline_QC_only';
% datafile_suffix = 'beta20240904_alldepths';
% datafile_suffix = 'beta20241206_newbin';
lat_interval = 4; lon_interval = 8;
% lat_interval = 3; lon_interval = 3;
res_text = '';
if lat_interval~=4 || lon_interval ~=8
    res_text = ['res_' num2str(lat_interval) '_' num2str(lon_interval)];
end
load([GLOBESINK_data_folder datafile_name '_' datafile_suffix res_text '.mat']) 
load([GLOBESINK_data_folder datafile_name2 '_' datafile_suffix '.mat']) 
load([GLOBESINK_data_folder datafile_name3 '_' datafile_suffix res_text '.mat']) 

zmids = midpoints(zbin_edges)';

if run_monthly_maps
%% CALCULATE POC AND FLUX (MONTHLY MAPS)

% CORRECT POC FOR LOSS OF ORGANIC MATTER WITH DEPTH
[GSm,GSn,GSo,GSp] = size(monthly_maps.spikes2.BBP700);
% TOP 100 M (LINEAR CORRECTION)
POC_bbp_correction_top100 = (1+(100-zmids)*flux_metadata.POC_bbp_zcorrect_slope_top100);
% BELOW 100 M (POWER LAW CORRECTION
uncertainty_suffices = {'','_upper','_lower'};
for six = 1:length(POC_size_suffices)
    for uix = 1:length(uncertainty_suffices)
        POC_bbp_correction.(['POC' POC_size_suffices{six} uncertainty_suffices{uix}]) = ...
            (zmids/100).^flux_metadata.(['POC' POC_size_suffices{six} '_bbp_zcorrect_exponent' uncertainty_suffices{uix}]);
        POC_bbp_correction.(['POC' POC_size_suffices{six} uncertainty_suffices{uix}])(zmids<100) = POC_bbp_correction_top100(zmids<100);
    end
end

% Initialize depth-corrected total POC and flux
monthly_maps.POC.POC_total = zeros(GSm,GSn,GSo,GSp); 
monthly_maps.flux.POC_total = zeros(GSm,GSn,GSo,GSp); 


% loop through size classes to calculate POC, flux, and uncertainties
for six = 1:length(POC_size_suffices)
    ssuf = POC_size_suffices{six}; vtype = bbp_size_vtypes{six};
    % POC/bbp ratio
    POC_bbp_ratio_zresolved = flux_metadata.POC_bbp_ratio * repmat(POC_bbp_correction.(['POC' ssuf]),1,GSn,GSo,GSp);

    % figure(100+six);clf;hold on
    % plot(flux_metadata.POC_bbp_ratio * POC_bbp_correction.(['POC' ssuf]),zmids);axis ij
    % plot(flux_metadata.POC_bbp_ratio_upper * POC_bbp_correction.(['POC' ssuf]),zmids);axis ij
    % plot(flux_metadata.POC_bbp_ratio_lower * POC_bbp_correction.(['POC' ssuf]),zmids);axis ij
    % plot(flux_metadata.POC_bbp_ratio * POC_bbp_correction.(['POC' ssuf '_lower']),zmids);axis ij
    % plot(flux_metadata.POC_bbp_ratio * POC_bbp_correction.(['POC' ssuf '_upper']),zmids);axis ij

    % Depth-corrected POC
    monthly_maps.POC.(['POC' ssuf]) = monthly_maps.(vtype).BBP700 .* POC_bbp_ratio_zresolved;
    % POC/bbp uncertainty
    monthly_maps = GLOBESINK_generate_relative_uncertainty(monthly_maps,'POC',['POC' ssuf],'POC_bbp_ratio',...
        flux_metadata.POC_bbp_ratio_upper/flux_metadata.POC_bbp_ratio,flux_metadata.POC_bbp_ratio_lower/flux_metadata.POC_bbp_ratio);
    % Depth correction uncertainty
    monthly_maps.uncertainties.POC.(['POC' ssuf]).upper.POC_bbp_zcorrect_exponent = ...
        flux_metadata.POC_bbp_ratio * monthly_maps.(vtype).BBP700 .* repmat(POC_bbp_correction.(['POC' ssuf '_upper']),1,GSn,GSo,GSp) - monthly_maps.POC.(['POC' ssuf]);
    monthly_maps.uncertainties.POC.(['POC' ssuf]).lower.POC_bbp_zcorrect_exponent = monthly_maps.POC.(['POC' ssuf]) - ...
        flux_metadata.POC_bbp_ratio * monthly_maps.(vtype).BBP700 .* repmat(POC_bbp_correction.(['POC' ssuf '_lower']),1,GSn,GSo,GSp);

    % POC flux
    monthly_maps.flux.(['POC' ssuf]) = monthly_maps.POC.(['POC' ssuf]) .* flux_metadata.(['w' ssuf]);

    if ~strcmp(ssuf,'_s')
        % propogate uncertainty from BBP spike precision to POC
        % monthly_maps = GLOBESINK_propagate_relative_errors(monthly_maps,vtype,'BBP700','POC',['POC' ssuf]);
        monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,vtype,'BBP700','POC',['POC' ssuf],POC_bbp_ratio_zresolved);
    end

    % propogate uncertainty from POC to flux
    % monthly_maps = GLOBESINK_propagate_relative_errors(monthly_maps,'POC',['POC' ssuf],'flux',['POC' ssuf]);
    monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,'POC',['POC' ssuf],'flux',['POC' ssuf],flux_metadata.(['w' ssuf]));

    % Uncertainty from sinking speed
    monthly_maps = GLOBESINK_generate_relative_uncertainty(monthly_maps,'flux',['POC' ssuf],'sinking_speed',...
        flux_metadata.(['w' ssuf '_upper'])/flux_metadata.(['w' ssuf]),flux_metadata.(['w' ssuf '_lower'])/flux_metadata.(['w' ssuf]));

    % Quadratically add systematic errors
    monthly_maps = GLOBESINK_combine_systematic_errors(monthly_maps,'POC',['POC' ssuf]);
    monthly_maps = GLOBESINK_combine_systematic_errors(monthly_maps,'flux',['POC' ssuf]);

    % Constrain POC flux lower bound to be ≥0
    too_low = monthly_maps.uncertainties.flux.(['POC' ssuf]).lower.total_systematic>monthly_maps.flux.(['POC' ssuf]);
    monthly_maps.uncertainties.flux.(['POC' ssuf]).lower.total_systematic(too_low) = monthly_maps.flux.(['POC' ssuf])(too_low);

    % Add current size class to total POC
    monthly_maps.POC.POC_total = monthly_maps.POC.POC_total + monthly_maps.POC.(['POC' ssuf]); 

    % Add current size class to total POC flux
    monthly_maps.flux.POC_total = monthly_maps.flux.POC_total + monthly_maps.flux.(['POC' ssuf]); 
    
    % Propogate uncertainty from individual to total POC fluxes
    monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,'flux',['POC' ssuf],'flux','POC_total',1,0,['_' POC_size_names{six}],{'total_systematic'});
    if ~strcmp(ssuf,'_s')
        monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,'flux',['POC' ssuf],'flux','POC_total',1,0,['_' POC_size_names{six}],{'precision'});
    end
end
%%
% Quadratically add systematic errors
monthly_maps = GLOBESINK_combine_systematic_errors(monthly_maps,'flux','POC_total');
% Quadratically add precisions errors
monthly_maps = GLOBESINK_combine_precisions(monthly_maps,'flux','POC_total');

%% CALCULATE CHL/BB RATIO
monthly_maps.total.CHLA_BBP700_ratio = monthly_maps.total.CHLA./monthly_maps.total.BBP700;
monthly_maps.total.CHLA_BBP700_ratio_night = monthly_maps.total.CHLA_NIGHT./monthly_maps.total.BBP700_NIGHT;
monthly_maps.n.CHLA_BBP700_ratio = monthly_maps.n.CHLA;
monthly_maps.n.CHLA_BBP700_ratio_night = monthly_maps.n.CHLA_NIGHT;
monthly_maps.baseline2.CHLA_BBP700_ratio = monthly_maps.baseline2.CHLA./monthly_maps.baseline2.BBP700;
monthly_maps.nfilt.CHLA_BBP700_ratio = monthly_maps.nfilt.BBP700;
monthly_maps.baseline2.CHLA_ADJUSTED_BBP700_ratio = monthly_maps.baseline2.CHLA_ADJUSTED./monthly_maps.baseline2.BBP700;
monthly_maps.nfilt.CHLA_ADJUSTED_BBP700_ratio = monthly_maps.nfilt.BBP700;
monthly_maps.baseline2.CHLA_ADJUSTED_BBP700_ratio_night = monthly_maps.baseline2.CHLA_ADJUSTED_NIGHT./monthly_maps.baseline2.BBP700_NIGHT;
monthly_maps.nfilt.CHLA_ADJUSTED_BBP700_ratio_night = monthly_maps.nfilt.BBP700;
%% GLOBESINK monthly maps spatial interpolation
min_n = 10;
monthly_maps_interpolated = GLOBESINK_spatial_interpolation(monthly_maps,min_n,lat_interval,lon_interval,lat_edges,lon_edges);
%% Uncertainty bounds for interpolated maps
% loop through size classes to calculate POC, flux, and uncertainties
for six = 1:length(POC_size_suffices)
    ssuf = POC_size_suffices{six}; vtype = bbp_size_vtypes{six};
    % POC/bbp ratio
    POC_bbp_ratio_zresolved = flux_metadata.POC_bbp_ratio * repmat(POC_bbp_correction.(['POC' ssuf]),1,GSn,GSo,GSp);
    % POC/bbp uncertainty
    monthly_maps_interpolated = GLOBESINK_generate_relative_uncertainty(monthly_maps_interpolated,'POC',['POC' ssuf],'POC_bbp_ratio',...
        flux_metadata.POC_bbp_ratio_upper/flux_metadata.POC_bbp_ratio,flux_metadata.POC_bbp_ratio_lower/flux_metadata.POC_bbp_ratio);
    % Depth correction uncertainty
    monthly_maps_interpolated.uncertainties.POC.(['POC' ssuf]).upper.POC_bbp_zcorrect_exponent = ...
        flux_metadata.POC_bbp_ratio * monthly_maps_interpolated.(vtype).BBP700 .* repmat(POC_bbp_correction.(['POC' ssuf '_upper']),1,GSn,GSo,GSp) - monthly_maps_interpolated.POC.(['POC' ssuf]);
    monthly_maps_interpolated.uncertainties.POC.(['POC' ssuf]).lower.POC_bbp_zcorrect_exponent = monthly_maps_interpolated.POC.(['POC' ssuf]) - ...
        flux_metadata.POC_bbp_ratio * monthly_maps_interpolated.(vtype).BBP700 .* repmat(POC_bbp_correction.(['POC' ssuf '_lower']),1,GSn,GSo,GSp);

    if ~strcmp(ssuf,'_s')
        % propogate uncertainty from BBP spike precision to POC
        monthly_maps_interpolated = GLOBESINK_propagate_errors_linear(monthly_maps_interpolated,vtype,'BBP700','POC',['POC' ssuf],POC_bbp_ratio_zresolved);
    end

    % propogate uncertainty from POC to flux
    monthly_maps_interpolated = GLOBESINK_propagate_errors_linear(monthly_maps_interpolated,'POC',['POC' ssuf],'flux',['POC' ssuf],flux_metadata.(['w' ssuf]));

    % Uncertainty from sinking speed
    monthly_maps_interpolated = GLOBESINK_generate_relative_uncertainty(monthly_maps_interpolated,'flux',['POC' ssuf],'sinking_speed',...
        flux_metadata.(['w' ssuf '_upper'])/flux_metadata.(['w' ssuf]),flux_metadata.(['w' ssuf '_lower'])/flux_metadata.(['w' ssuf]));

    % Quadratically add systematic errors
    monthly_maps_interpolated = GLOBESINK_combine_systematic_errors(monthly_maps_interpolated,'POC',['POC' ssuf]);
    monthly_maps_interpolated = GLOBESINK_combine_systematic_errors(monthly_maps_interpolated,'flux',['POC' ssuf]);

    % Constrain POC flux lower bound to be ≥0
    too_low = monthly_maps_interpolated.uncertainties.flux.(['POC' ssuf]).lower.total_systematic>monthly_maps_interpolated.flux.(['POC' ssuf]);
    monthly_maps_interpolated.uncertainties.flux.(['POC' ssuf]).lower.total_systematic(too_low) = monthly_maps_interpolated.flux.(['POC' ssuf])(too_low);
    
    % Propogate uncertainty from individual to total POC fluxes
    monthly_maps_interpolated = GLOBESINK_propagate_errors_linear(monthly_maps_interpolated,'flux',['POC' ssuf],'flux','POC_total',1,0,['_' POC_size_names{six}],{'total_systematic'});
end
%
% Quadratically add systematic errors
monthly_maps_interpolated = GLOBESINK_combine_systematic_errors(monthly_maps_interpolated,'flux','POC_total');
% Quadratically add precisions errors
monthly_maps_interpolated = GLOBESINK_combine_precisions(monthly_maps_interpolated,'flux','POC_total');

%% save GLOBESINK monthly maps
save([GLOBESINK_data_folder datafile_name '_' datafile_suffix res_text '_fluxes_interpolated.mat'],'monthly_maps_interpolated','zbin_edges','lat_edges','lon_edges','flux_metadata','-v7.3') 
save([GLOBESINK_data_folder datafile_name '_' datafile_suffix res_text '_fluxes.mat'],'monthly_maps','zbin_edges','lat_edges','lon_edges','flux_metadata','-v7.3') 
end

%% CALCULATE POC (YEARLY MONTHLY MAPS)
if run_yearly_monthly_maps
[GSm,GSn,GSo,GSp,GSq] = size(yearly_monthly_maps.spikes2.BBP700);
yearly_monthly_maps.POC.POC_total = zeros(size(GSm,GSn,GSo,GSp,GSq));
yearly_monthly_maps.flux.POC_total = zeros(size(GSm,GSn,GSo,GSp,GSq));
for six = 1:length(POC_size_suffices)
    ssuf = POC_size_suffices{six}; vtype = bbp_size_vtypes{six};
    yearly_monthly_maps.POC.(['POC' ssuf]) = yearly_monthly_maps.(vtype).BBP700*flux_metadata.POC_bbp_ratio;
    yearly_monthly_maps.POC.(['POC' ssuf]) = yearly_monthly_maps.POC.(['POC' ssuf]) .* repmat(POC_bbp_correction.(['POC' ssuf]),1,GSn,GSo,GSp,GSq);
    yearly_monthly_maps.POC.POC_total = yearly_monthly_maps.POC.POC_total+yearly_monthly_maps.POC.(['POC' ssuf]);

    %% CALCULATE POC FLUX (YEARLY MONTHLY MAPS)
    yearly_monthly_maps.flux.(['POC' ssuf]) = yearly_monthly_maps.POC.(['POC' ssuf]) .* flux_metadata.(['w' ssuf]);
    yearly_monthly_maps.flux.POC_total = yearly_monthly_maps.flux.POC_total+yearly_monthly_maps.flux.(['POC' ssuf]);
end
save([GLOBESINK_data_folder datafile_name3 '_' datafile_suffix res_text '_fluxes.mat'],'yearly_monthly_maps','zbin_edges','lat_edges','lon_edges','map_years','flux_metadata','-v7.3') 
end
% %% vertically smoothed product
% generate_old_smoothed_product = 0;
% if generate_old_smoothed_product
% fvars = fieldnames(monthly_maps.flux);
% for fvix = 1:length(fvars)
%     vname = fvars{fvix};
%     monthly_maps.flux_vert_smoothed.(vname) = monthly_maps.flux.(vname);
%     for jj = 1:GSn
%         for kk = 1:GSo
%             for ll = 1:GSp
%                 monthly_maps.flux_vert_smoothed.(vname)(:,jj,kk,ll) = running_mean(monthly_maps.flux.(vname)(:,jj,kk,ll),3);
%             end
%         end
%     end
% end
% end

%% CALCULATE POC (MONTHLY BINS)
if run_monthly_bins
[GSm,GSn,GSo] = size(monthly_bins.spikes2.BBP700);
monthly_bins.POC.POC_total = zeros(size(GSm,GSn,GSo));
monthly_bins.flux.POC_total = zeros(size(GSm,GSn,GSo));
for six = 1:length(POC_size_suffices)
    ssuf = POC_size_suffices{six}; vtype = bbp_size_vtypes{six};
    monthly_bins.POC.(['POC' ssuf]) = monthly_bins.(vtype).BBP700*flux_metadata.POC_bbp_ratio;
    monthly_bins.POC.(['POC' ssuf]) = monthly_bins.POC.(['POC' ssuf]) .* repmat(POC_bbp_correction.(['POC' ssuf]),1,GSn,GSo);
    monthly_bins.POC.POC_total = monthly_bins.POC.POC_total+monthly_bins.POC.(['POC' ssuf]);

    %% CALCULATE POC FLUX (YEARLY MONTHLY MAPS)
    monthly_bins.flux.(['POC' ssuf]) = monthly_bins.POC.(['POC' ssuf]) .* flux_metadata.(['w' ssuf]);
    monthly_bins.flux.POC_total = monthly_bins.flux.POC_total+monthly_bins.flux.(['POC' ssuf]);
end
monthly_bins.total.CHLA_BBP700_ratio = monthly_bins.total.CHLA./monthly_bins.total.BBP700;
monthly_bins.total.CHLA_BBP700_ratio_night = monthly_bins.total.CHLA_NIGHT./monthly_bins.total.BBP700_NIGHT;
monthly_bins.n.CHLA_BBP700_ratio = monthly_bins.n.CHLA;
monthly_bins.n.CHLA_BBP700_ratio_night = monthly_bins.n.CHLA_NIGHT;
monthly_bins.baseline2.CHLA_BBP700_ratio = monthly_bins.baseline2.CHLA./monthly_bins.baseline2.BBP700;
monthly_bins.nfilt.CHLA_BBP700_ratio = monthly_bins.nfilt.BBP700;
monthly_bins.baseline2.CHLA_ADJUSTED_BBP700_ratio = monthly_bins.baseline2.CHLA_ADJUSTED./monthly_bins.baseline2.BBP700;
monthly_bins.nfilt.CHLA_ADJUSTED_BBP700_ratio = monthly_bins.nfilt.BBP700;
monthly_bins.baseline2.CHLA_ADJUSTED_BBP700_ratio_night = monthly_bins.baseline2.CHLA_ADJUSTED_NIGHT./monthly_bins.baseline2.BBP700_NIGHT;
monthly_bins.nfilt.CHLA_ADJUSTED_BBP700_ratio_night = monthly_bins.nfilt.BBP700;
save([GLOBESINK_data_folder datafile_name2 '_' datafile_suffix '_fluxes.mat'],'monthly_bins','zbin_edges','t_edges','float_WMOs','flux_metadata','-v7.3') 
end

% [GSm,GSn,GSo] = size(monthly_bins.spikes2.BBP700);
% monthly_bins.POC.POC_l = monthly_bins.spikes2.BBP700*flux_metadata.POC_bbp_ratio;
% monthly_bins.POC.POC_s = monthly_bins.baseline2.BBP700*flux_metadata.POC_bbp_ratio;
% POC_bbp_correction_z = zmids; POC_bbp_correction_z(zmids<100)= 100;
% POC_bbp_correction.POC_l = (POC_bbp_correction_z/100).^flux_metadata.POC_l_bbp_zcorrect_exponent;
% POC_bbp_correction.POC_s = (POC_bbp_correction_z/100).^flux_metadata.POC_s_bbp_zcorrect_exponent;
% monthly_bins.POC.POC_l = monthly_bins.POC.POC_l .* repmat(POC_bbp_correction.POC_l,1,GSn,GSo);
% monthly_bins.POC.POC_s = monthly_bins.POC.POC_s .* repmat(POC_bbp_correction.POC_s,1,GSn,GSo);
% monthly_bins.POC.POC_total = monthly_bins.POC.POC_s+monthly_bins.POC.POC_l;
% %% CALCULATE POC FLUX (MONTHLY BINS)
% monthly_bins.flux.POC_l = monthly_bins.POC.POC_l * flux_metadata.w_l;
% monthly_bins.flux.POC_s = monthly_bins.POC.POC_s * flux_metadata.w_s;
% monthly_bins.flux.POC_total = monthly_bins.flux.POC_s+monthly_bins.flux.POC_l;

%% SAVE GLOBESINK FLUX PRODUCTS
% save([data_folder 'BGC_Argo_monthly_maps_' datafile_name '_test_hires.mat'],'monthly_maps','zbin_edges','lat_edges','lon_edges','-v7.3')
