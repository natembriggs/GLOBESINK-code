function [monthly_bins] = GLOBESINK_monthly_perfloat_bins(t_edges,bin_opts,float_WMOs,percast_vnames,mat_file_folder,exclude_near_shelf,QC_text)
% [monthly_bins] = GLOBESINK_monthly_perfloat_bins(t_edges,zbin_edges,float_WMOs,vars_to_bin,vars_to_filter,percast_vnames,mat_file_folder,exclude_near_shelf)
%
%%
zbin_edges = bin_opts.zbin_edges;
vars_to_filter = bin_opts.vars_to_filter;
vars_to_bin = bin_opts.vars_to_bin;
ntbins = length(t_edges)-1; % Number of time bins
nfloats = length(float_WMOs); % Number of floats
zbin_mids = midpoints(zbin_edges)'; % Middle of depth bins
nzbins = length(zbin_mids); % Number of depth bins
% Dimensions for multi-dimensional array
m = nzbins; n = ntbins; o = nfloats;

% QC_text = '';
% if ~apply_manual_QC; QC_text = [QC_text '_no_manual_QC']; end
% if ~apply_auto_QC; QC_text = [QC_text '_no_auto_QC']; end

% Create table for dates
dtable = table();
[dtable.yy,dtable.mm,dtable.dd] = datevec(t_edges(1:end-1)');
% recalc_monthly_maps = 0;
% if recalc_monthly_maps

%%
for vix = 1:length(vars_to_bin)
    vname = vars_to_bin{vix};
    monthly_bins.total.(vname) = nan(m,n,o); % average in bin
    monthly_bins.n.(vname) = zeros(m,n,o); % number of samples in bin
    monthly_bins.total.([vname '_ADJUSTED']) = nan(m,n,o); % average in bin
    monthly_bins.n.([vname '_ADJUSTED']) = zeros(m,n,o); % number of samples in bin
end
% vars_to_filter = [vars_to_filter {'BBP700_ADJUSTED','CHLA_ADJUSTED'}];
for vix = 1:length(vars_to_filter)
    vname = vars_to_filter{vix};
    monthly_bins.baseline_med.(vname) = nan(m,n,o); % mean baseline with spikes removed via median filter
    monthly_bins.spikes_med.(vname) = nan(m,n,o); % mean spikes calculated via median filter (see GLOBESINK_per_profile_binning.m; 5 point running median?)
    monthly_bins.baseline_med_nobig.(vname) = nan(m,n,o); % same as above, but with "big" spikes removed
    monthly_bins.spikes_med_nobig.(vname) = nan(m,n,o);

    monthly_bins.baseline.(vname) = nan(m,n,o); % using running min followed by running max
    monthly_bins.spikes_noise.(vname) = nan(m,n,o); % spikes below min spike threshold
    monthly_bins.spikes.(vname) = nan(m,n,o); % spikes between min and max spike thresholds
    monthly_bins.spikes_small.(vname) = nan(m,n,o); % spikes between min and mid spike thresholds
    monthly_bins.spikes_medium.(vname) = nan(m,n,o); % spikes between mid and max spike thresholds
    monthly_bins.spikes_big.(vname) = nan(m,n,o); % spikes above max spike threshold (see GLOBESINK_per_profile_binning.m)

    monthly_bins.baseline2.(vname) = nan(m,n,o); % using running min followed by running max
    monthly_bins.spikes_noise2.(vname) = nan(m,n,o); % spikes below min spike threshold
    monthly_bins.spikes2.(vname) = nan(m,n,o); % spikes between min and max spike thresholds
    monthly_bins.spikes_small2.(vname) = nan(m,n,o); % spikes between min and mid spike thresholds
    monthly_bins.spikes_medium2.(vname) = nan(m,n,o); % spikes between mid and max spike thresholds
    monthly_bins.spikes_big2.(vname) = nan(m,n,o); % spikes above max spike threshold (see GLOBESINK_per_profile_binning.m)
    spike_number_vtypes = {'spikes2','spikes_big2','spikes_small2','spikes_medium2'};
    for vtix = 1:length(spike_number_vtypes)
            monthly_bins.([spike_number_vtypes{vtix} '_n']).(vname) = nan(m,n,o); % number of spikes in bin
    end
    %             pc_bins1.(float_name).baseline2.(vname) = nan(m,n,o);
    %             pc_bins1.(float_name).spikes2.(vname) = nan(m,n,o);
    monthly_bins.var.(vname) = nan(m,n,o); % standard deviation within the bin
    monthly_bins.var_nobig.(vname) = nan(m,n,o); % same with big spikes removed
    monthly_bins.nfilt.(vname) = nan(m,n,o); % number of data points after bad data are removed
    monthly_bins.PSD_slope.(vname) = nan(m,n,o); % number of data points after bad data are removed
end
monthly_bins.D_mean.BBP700 = nan(m,n,o);
monthly_bins.D_mean_nobig.BBP700 = nan(m,n,o);
monthly_bins.D_mean.BBP700_2 = nan(m,n,o);
monthly_bins.D_mean_nobig.BBP700_2 = nan(m,n,o);

night_vnames = {'CHLA','CHLA_ADJUSTED','BBP700'};
for vix = 1:length(night_vnames)
    vname = night_vnames{vix};
    monthly_bins.total.([vname '_NIGHT']) = nan(m,n,o);
    monthly_bins.baseline2.([vname '_NIGHT']) = nan(m,n,o);
    monthly_bins.n.([vname '_NIGHT']) = zeros(m,n,o);
    monthly_bins.nfilt.([vname '_NIGHT']) = zeros(m,n,o);
end

vtypes = fieldnames(monthly_bins);

% initialize uncertainties
for vix = 1:length(vars_to_filter)
    vname = vars_to_filter{vix};
    monthly_bins.uncertainties.PSD_slope.(vname).upper.precision = nan(m,n,o);
    monthly_bins.uncertainties.PSD_slope.(vname).lower.precision = nan(m,n,o);
end

for vix = 1:length(percast_vnames)
    vname = percast_vnames{vix};
    monthly_bins.(vname) = nan(1,n,o);
end

%% loop through float WMOs
for fix = 1:length(float_WMOs)
    this_WMO = float_WMOs(fix);
    pcbin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins' QC_text '.mat'];
    if exist(pcbin_fname,'file')
    % load(pcbin_fname,'pc_bins1');
    load(pcbin_fname);
    if isequaln(bin_opts,bin_opts1) % checking if bin options for single-float percast bin file match project bin options
    float_names = fieldnames(pc_bins1);
    float_name = float_names{1};
    % find data that is not near the continental shelf
    if exclude_near_shelf
        gz = pc_bins1.(float_name).bath_Z_nearby<-300;
    else
        gz = true(size(pc_bins1.(float_name).bath_Z_nearby));
    end
    if any(gz)
    % find min and max time for this float
    mint = min(pc_bins1.(float_name).M_TIME(gz)); maxt = max(pc_bins1.(float_name).M_TIME(gz));
    start_tix = find(t_edges<mint,1,'last'); end_tix = min(find(t_edges<maxt,1,'last'),ntbins); 
    zbin_bottoms = zbin_edges(2:end)'*ones(size(pc_bins1.(float_name).M_TIME));
    bath_z_nearby_mat = ones(length(zbin_edges)-1,1)*pc_bins1.(float_name).bath_Z_nearby;
    is_near_bottom = zbin_bottoms>(-bath_z_nearby_mat-200);
    zenith = get_sun_zenith_angle(pc_bins1.(float_name).M_TIME',pc_bins1.(float_name).LATITUDE',pc_bins1.(float_name).LONGITUDE');
    %% add nighttime Chla
    for vix = 1:length(night_vnames)
        vname = night_vnames{vix};
        if isfield(pc_bins1.(float_name).total,vname)
            pc_bins1.(float_name).total.([vname '_NIGHT']) = pc_bins1.(float_name).total.(vname);
            pc_bins1.(float_name).total.([vname '_NIGHT'])(:,zenith>5) = nan;
            pc_bins1.(float_name).n.([vname '_NIGHT']) = pc_bins1.(float_name).n.(vname);
            pc_bins1.(float_name).n.([vname '_NIGHT'])(:,zenith>5) = 0;
        end
        if isfield(pc_bins1.(float_name).baseline2,vname)
            pc_bins1.(float_name).baseline2.([vname '_NIGHT']) = pc_bins1.(float_name).baseline2.(vname);
            pc_bins1.(float_name).baseline2.([vname '_NIGHT'])(:,zenith>5) = nan;
            pc_bins1.(float_name).nfilt.([vname '_NIGHT']) = pc_bins1.(float_name).nfilt.(vname);
            pc_bins1.(float_name).nfilt.([vname '_NIGHT'])(:,zenith>5) = 0;
        end
    end
    % loop through time bins
    for tix = start_tix:end_tix
        gt = gz & is_between(pc_bins1.(float_name).M_TIME,t_edges(tix),t_edges(tix+1));
        if any(gt) % check if there is any good data in this time bin
        gtixs = find(gt); mid_tix = gtixs(ceil(end/2));
        monthly_bins.LATITUDE(1,tix,fix) = pc_bins1.(float_name).LATITUDE(mid_tix);
        monthly_bins.LONGITUDE(1,tix,fix) = pc_bins1.(float_name).LONGITUDE(mid_tix);
        g1 = gt&~isnan(pc_bins1.(float_name).M_TIME);
        if any(g1)
            monthly_bins.M_TIME(1,tix,fix) = mean(pc_bins1.(float_name).M_TIME(g1));
        end
        % loop through variable types (e.g. total, baseline, spikes...)
        for vtix = 1:length(vtypes)
            vtype = vtypes{vtix};
            if isfield(pc_bins1.(float_name),vtype)
            vnames = fieldnames(pc_bins1.(float_name).(vtype));
            % loop through variable names
            for vix = 1:length(vnames)
                vname = vnames{vix};
                if isfield(pc_bins1.(float_name).(vtype),vname)
                v = pc_bins1.(float_name).(vtype).(vname);
                if strcmp(vtype,'total')||strcmp(vtype,'n')
                    n = pc_bins1.(float_name).n.(vname);
                else
                    n = pc_bins1.(float_name).nfilt.(vname);
                end
                if strcmp(vtype,'n') || strcmp(vtype,'nfilt') || ...
                        (length(vtype)>2 && strcmp(vtype((end-1):end),'_n'))
                    % add together number of samples in bin
                    if exclude_near_shelf
                        v(is_near_bottom) = 0;
                    end
                    monthly_bins.(vtype).(vname)(:,tix,fix) = nansum(v(:,gt(1:size(v,2))),2);
                else
                    % calculate mean within bin
                    if exclude_near_shelf
                        v(is_near_bottom) = nan;
                        n(is_near_bottom) = 0;
                    end
                    badv = isnan(v+n) | isinf(v); 
                    if length(vtype)>=3 && strcmp(vtype(1:3),'var')
                        badv = badv | n<2;
                    end
                    v(badv) = 0; n(badv) = 0;
                    thisv = v(:,gt(1:size(v,2)));
                    thisn = n(:,gt(1:size(v,2)));
                    if length(vtype)>=6 && strcmp(vtype(1:6),'spikes')
                        % weighted mean for spikes
                        gn = sum(thisn,2)>0;
                        monthly_bins.(vtype).(vname)(gn,tix,fix) = sum(thisv(gn,:).*thisn(gn,:),2)./ ...
                            sum(thisn(gn,:),2);
                    elseif length(vtype)>=3 && strcmp(vtype(1:3),'var')
                        % pooled variance
                        gn = sum(thisn,2)>1;
                        n_minus_one = thisn-1;
                        monthly_bins.(vtype).(vname)(gn,tix,fix) = sum(thisv(gn,:).*n_minus_one(gn,:),2)./ ...
                            sum(n_minus_one(gn,:),2);
                    elseif strcmp(vtype,'PSD_slope') && strcmp(vname,'BBP700')
                        % inverse variance weighting for PSD slope mean and CI
                        ci_lo = pc_bins1.(float_name).uncertainties.(vtype).(vname).lower.precision(:,gt(1:size(v,2)));
                        ci_hi = pc_bins1.(float_name).uncertainties.(vtype).(vname).upper.precision(:,gt(1:size(v,2)));
                        [mu_pool, ci_lo_pool, ci_hi_pool] = poolMeansIVW(thisv, thisv-ci_lo, thisv+ci_hi, 0.05,2);
                        monthly_bins.(vtype).(vname)(:,tix,fix) = mu_pool;
                        monthly_bins.uncertainties.(vtype).(vname).lower.precision(:,tix,fix) = mu_pool-ci_lo_pool;
                        monthly_bins.uncertainties.(vtype).(vname).upper.precision(:,tix,fix) = ci_hi_pool-mu_pool;
                    else % straight mean for non-spike variables
                        thisv(thisn==0) = nan;
                        monthly_bins.(vtype).(vname)(:,tix,fix) = nanmean(thisv,2);
                    end
                end
                end
            end %variable names
            end
        end % variable types
        end
    end % time bins
    end
    else
        disp(['WARNING!!! bin options for ' pcbin_fname ' do not match project bin options. not including in monthly perfloat bins'])
    end
    else
        disp([pcbin_fname ' not found'])
    end
end % loop through floats

%% get uncertainties for number of spikes
for vix = 1:length(vars_to_filter)
    vname = vars_to_filter{vix};
    for vtix = 1:length(spike_number_vtypes)
        vtype = spike_number_vtypes{vtix};
        [~,nspikes_upper] = poissonUpperBoundChi2(monthly_bins.([vtype '_n']).(vname), 0.05);
        [~,nspikes_lower] = poissonLowerBoundChi2(monthly_bins.([vtype '_n']).(vname), 0.05);
        monthly_bins.uncertainties.([vtype '_n']).(vname).upper.precision = nspikes_upper;
        monthly_bins.uncertainties.([vtype '_n']).(vname).lower.precision = nspikes_lower;
    end
end
%% get uncertainties for mean and var
monthly_bins = GLOBESINK_get_spike_uncertainties(monthly_bins,bin_opts);
%% get mean diameters
size_suffices = {'','_nobig'};
monthly_bins = GLOBESINK_calculate_mean_ESD(monthly_bins,bin_opts,size_suffices);
%% get number concentrations
size_suffices = {'_small2','_medium2','_big2'};
monthly_bins = GLOBESINK_calculate_number_concentrations(monthly_bins,bin_opts,size_suffices);


