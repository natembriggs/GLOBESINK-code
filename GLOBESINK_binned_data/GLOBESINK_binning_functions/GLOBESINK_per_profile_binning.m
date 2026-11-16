function [pc_bins,bin_opts] = GLOBESINK_per_profile_binning(biofloat,biofloat_QC,vars_to_bin,apply_manual_QC,apply_auto_QC,remove_bbp_spike_clusters,remove_FDOM_spikes,zbin_edges)
% [pc_bins,bin_opts] = GLOBESINK_per_profile_binning(biofloat,biofloat_QC,vars_to_bin,apply_manual_QC,apply_auto_QC,remove_bbp_spike_clusters,remove_FDOM_spikes,zbin_edges);

% vars_to_bin = [key_import_variables optional_variables];

bin_opts.V = 10; % cm^3
bin_opts.Q = 0.024; %
% bin_opts.Q = 0.024/2; %
bin_opts.PSD_slope_lit_range = [3.3 4.5];

bin_opts.med_spike_window1 = 5;
% med_spike_window2 = 15;

bin_opts.spike_filter_window1 = 15;
bin_opts.spike_filter_window2 = 5;
% spike_filter_window = 5;

if nargin<8
    % zbin_edges = [0 10 50 100:50:900 975 1025 1200:200:1600 1900 2100]; % meters
    zbin_edges = [0 10 50 100:50:900 1000 1200:200:1800 2100]; % meters
    if nargin<7; remove_FDOM_spikes = 0;
    if nargin<6; remove_bbp_spike_clusters = 0;
    if nargin<5; apply_auto_QC = 1;
    if nargin <4; apply_manual_QC = 1; end; end; end; end
end
% zbin_edges = [0 20 50 100:50:900 975 1025 1200:200:1600 1900 2100]; % meters
zbin_mids = midpoints(zbin_edges)';
nzbins = length(zbin_mids);

bin_opts.zbin_edges = zbin_edges;
% bin_opts.z_variable = 'PRES';
bin_opts.z_variable = 'depth';
bin_opts.remove_bottom_30m = 'true';

if ~ismember(bin_opts.z_variable,vars_to_bin)
    vars_to_bin = [{bin_opts.z_variable} vars_to_bin];
end

bin_opts.vars_to_bin = vars_to_bin;

% size_bounds = [50 2.^(6:(1/3):15)];
% size_widths = diff(size_bounds);
% size_mids = midpoints(size_bounds);
% for six = 1:length(size_mids)
%     size_mid_names{six} = num2str(round(size_mids(six)));
% end
% size_mids_good = size_mids([1 3:17]);
% size_widths_good = size_widths([1 3:17]);
%%
% if include_adjusted_data
    for vix = 1:length(vars_to_bin)
        vars_to_bin{end+1} = [vars_to_bin{vix} '_ADJUSTED'];
    end
% end

bin_opts.vars_to_filter = {'BBP700','BBP700_2','CHLA','CHLA_ADJUSTED'};%,'BBP532','BBP470'};%,'CP660','CDOM'};
bin_opts.size_vars = {'BBP700','BBP700_2'};

spike_number_vtypes = {'spikes2','spikes_big2','spikes_small2','spikes_medium2'};

bin_opts.small_spike.CHLA = 0.04; bin_opts.medium_spike.CHLA = 0.63; bin_opts.big_spike.CHLA = 10;
bin_opts.small_spike.CHLA_ADJUSTED = bin_opts.small_spike.CHLA; bin_opts.medium_spike.CHLA_ADJUSTED = bin_opts.medium_spike.CHLA; bin_opts.big_spike.CHLA_ADJUSTED = bin_opts.big_spike.CHLA;
big_bbp_spike_diameter = 0.812; % mm
medium_bbp_spike_diameter = 0.406; % mm
small_bbp_spike_diameter = 0.203; % mm
bin_opts.big_bbp_spike_diameter = big_bbp_spike_diameter;
bin_opts.medium_bbp_spike_diameter = medium_bbp_spike_diameter;
bin_opts.small_bbp_spike_diameter = small_bbp_spike_diameter;
bin_opts.small_spike.BBP700 = pi/4*(small_bbp_spike_diameter/10)^2*bin_opts.Q/bin_opts.V*100; 
bin_opts.medium_spike.BBP700 = pi/4*(medium_bbp_spike_diameter/10)^2*bin_opts.Q/bin_opts.V*100; 
bin_opts.big_spike.BBP700 = pi/4*(big_bbp_spike_diameter/10)^2*bin_opts.Q/bin_opts.V*100;
bin_opts.small_spike.BBP700_2 = bin_opts.small_spike.BBP700;
bin_opts.medium_spike.BBP700_2 = bin_opts.medium_spike.BBP700;
bin_opts.big_spike.BBP700_2 = bin_opts.big_spike.BBP700;
bin_opts.small_spike.BBP532 = bin_opts.small_spike.BBP700/0.79;
bin_opts.medium_spike.BBP532 = bin_opts.medium_spike.BBP700/0.79;
bin_opts.big_spike.BBP532 = bin_opts.big_spike.BBP700/0.79;
bin_opts.small_spike.BBP470 = bin_opts.small_spike.BBP700/0.7542;
bin_opts.medium_spike.BBP470 = bin_opts.medium_spike.BBP700/0.7542;
bin_opts.big_spike.BBP470 = bin_opts.big_spike.BBP700/0.7542;
bin_opts.bbp_var_blank = 6e-10*2*0;
bin_opts.bbp_blank = 2e-4*0;

clear Diameter_limits
Diameter_limits.spikes_med = [small_bbp_spike_diameter 10]; % mm
Diameter_limits.spikes_med_nobig = [small_bbp_spike_diameter big_bbp_spike_diameter];
Diameter_limits.spikes_small2 = [small_bbp_spike_diameter medium_bbp_spike_diameter];
Diameter_limits.spikes_medium2 = [medium_bbp_spike_diameter big_bbp_spike_diameter];
Diameter_limits.spikes_big2 = [big_bbp_spike_diameter 10]; % mm
Diameter_limits.spikes2 = [small_bbp_spike_diameter big_bbp_spike_diameter];
spike_uncertainty_vtypes = fieldnames(Diameter_limits);
bin_opts.diameter_limits_mm = Diameter_limits;

%% loop through individual floats
float_names = fieldnames(biofloat);
for fix = 1:length(float_names)
    float_name = float_names{fix};
    [pnums,pstart_ixs] = unique(biofloat.(float_name).CYCLE_NUMBER');
    if length(pnums)>=9 % automated QC uses a 9 profile running window
    lats = biofloat.(float_name).LATITUDE(pstart_ixs)';
    lons = biofloat.(float_name).LONGITUDE(pstart_ixs)';
    % REMOVE BAD DATA (BIG JUMPS IN LATITUDE)
    smoothlat = running_median(lats,3); smoothlon = running_median(lons,3);
    bad_ix = abs(lats-smoothlat)>1 | abs(lons-smoothlon)>3 | lons==0;% bad_ix(end) = 0;
    if ~bad_ix(2) && (diff(lons(1:2))>3 || diff(lats(1:2))>1)
        bad_ix(1) = true;
    end
    if any(bad_ix)
        lats(bad_ix) = smoothlat(bad_ix);
        lons(bad_ix) = smoothlon(bad_ix);
    end
    t = biofloat.(float_name).M_TIME(pstart_ixs)';
    pc_bins.(float_name).LATITUDE = lats;
    pc_bins.(float_name).LONGITUDE = lons;
    pc_bins.(float_name).M_TIME = t;
    pc_bins.(float_name).PRES = zbin_mids;
    pc_bins.(float_name).CYCLE_NUMBER = pnums;
    m = nzbins; n = length(t);
    %% initialize all bins
    for vix = 1:length(vars_to_bin)
        vname = vars_to_bin{vix};
        if isfield(biofloat.(float_name),vname)
            pc_bins.(float_name).total.(vname) = nan(m,n);
            pc_bins.(float_name).n.(vname) = zeros(m,n);
        end
    end
    % initialize spike and baseline bins
    for vix = 1:length(bin_opts.vars_to_filter)
        vname = bin_opts.vars_to_filter{vix};
        if isfield(biofloat.(float_name),vname)
            vtypes_to_initialize = {'baseline_med','spikes_med','baseline_med_nobig',...
                'spikes_med_nobig','baseline','spikes_noise','spikes','spikes_small',...
                'spikes_medium','spikes_big','baseline2','spikes2','spikes_small2',...
                'spikes_medium2','spikes_noise2','spikes_big2','spikes2_n',...
                'spikes_small2_n','spikes_medium2_n','spikes_big2_n','var','var_nobig',...
                'PSD_slope'};
            for vtix = 1:length(vtypes_to_initialize)
                vtype = vtypes_to_initialize{vtix};
                pc_bins.(float_name).(vtype).(vname) = nan(m,n);
                % initialize uncertainties
                if ismember(vname,bin_opts.size_vars)&&ismember(vtype,{'spikes2_n',...
                        'spikes_small2_n','spikes_medium2_n','spikes_big2_n','PSD_slope'})
                    pc_bins.(float_name).uncertainties.(vtype).(vname).upper.precision = nan(m,n);
                    pc_bins.(float_name).uncertainties.(vtype).(vname).lower.precision = nan(m,n);
                end
            end
           pc_bins.(float_name).nfilt.(vname) = zeros(m,n);
        end
    end
    %% calculate per-profile bins
    switch bin_opts.z_variable
        case 'PRES'
            z = biofloat.(float_name).PRES;
        case 'depth'
            z = -gsw_z_from_p(biofloat.(float_name).PRES,biofloat.(float_name).LATITUDE);
    end
    % loop through profiles
    for pix = 1:length(pnums)
        thisp = pnums(pix);
        gp = biofloat.(float_name).CYCLE_NUMBER == thisp;
        if bin_opts.remove_bottom_30m
            gp = gp & z<(max(z(gp))-30);
        end
        if sum(gp)>10
        thisz = z(gp);
        % loop calculate total mean and sample number for each variable
        for vix = 1:length(vars_to_bin)
            vname = vars_to_bin{vix};
            if isfield(biofloat.(float_name),vname)
            thisv = biofloat.(float_name).(vname)(gp);
            if length(vname)>9 && strcmp(vname(end-8:end),'_ADJUSTED')
                % for adjusted variables, use only QC 1 and 2
                if isfield(biofloat.(float_name),[vname '_QC'])
                    thisqc = biofloat.(float_name).([vname '_QC'])(gp);
                    thisv(~ismember(thisqc,['1' '2'])) = nan;
                end
            end
            if any(~isnan(thisv))
                [~, pc_bins.(float_name).total.(vname)(:,pix), pc_bins.(float_name).n.(vname)(:,pix), ~] = ...
                    binaverage_edges(thisz,thisv,zbin_edges);
            end
            end
        end
        % calculate mean spike and baseline stats for filtered variables
        for vix = 1:length(bin_opts.vars_to_filter)
            vname = bin_opts.vars_to_filter{vix};
            if isfield(biofloat.(float_name),vname)
            gv = gp&~isnan(biofloat.(float_name).(vname));
            if apply_manual_QC
                % gv = gv & ~biofloat_QC.(float_name).bad_Argo_profile_bbp;
                % gv = gv & ~biofloat_QC.(float_name).bad_Argo_QC_bbp;
                % gv = gv & ~biofloat_QC.(float_name).bad_bbp_in_greylist;
                gv = gv & ~biofloat_QC.(float_name).bad_bbp_GLOBESINK_manual;
            end
            if apply_auto_QC
                % gv = gv & ~biofloat_QC.(float_name).is_near_big_bbp_spike & ...
                %     ~biofloat_QC.(float_name).is_near_high_bbp_baseline & ...
                %     ~biofloat_QC.(float_name).is_low_bbp_baseline;
                gv = gv & ~biofloat_QC.(float_name).is_near_high_bbp_baseline & ...
                    ~biofloat_QC.(float_name).is_low_bbp_baseline;
                if isfield(biofloat_QC.(float_name),'is_near_cdom_spike') && remove_FDOM_spikes
                    gv = gv & ~biofloat_QC.(float_name).is_near_cdom_spike;
                end
                if remove_bbp_spike_clusters
                    gv = gv & ~biofloat_QC.(float_name).is_near_big_bbp_spike;
                end
            end
            if sum(gv)>10
            % apply various spike filters to variable
            thisv = biofloat.(float_name).(vname)(gv);
            thisz_filt = z(gv);
            [filtvars.baseline_med,filtvars.spikes_med] = separate_spikes_median(thisv,bin_opts.med_spike_window1);
            filtvars.baseline_med_nobig = filtvars.baseline_med; filtvars.spikes_med_nobig = filtvars.spikes_med;
            isbig = filtvars.spikes_med>bin_opts.big_spike.(vname);
            filtvars.baseline_med_nobig(isbig) = nan; filtvars.spikes_med_nobig(isbig) = nan;
            % spike window 1
            [filtvars.baseline,spikes] = separate_spikes(thisv,bin_opts.spike_filter_window1);
            filtvars.spikes_noise = spikes; filtvars.spikes_noise(spikes>bin_opts.small_spike.(vname)) = 0;
            filtvars.spikes = spikes; filtvars.spikes(spikes<=bin_opts.small_spike.(vname)|spikes>bin_opts.big_spike.(vname)) = 0;
            filtvars.spikes_big = spikes; filtvars.spikes_big(spikes<=bin_opts.big_spike.(vname)) = 0;
            filtvars.spikes_small = spikes; filtvars.spikes_small(spikes<=bin_opts.small_spike.(vname)|spikes>bin_opts.medium_spike.(vname)) = 0;
            filtvars.spikes_medium = spikes; filtvars.spikes_medium(spikes<=bin_opts.medium_spike.(vname)|spikes>bin_opts.big_spike.(vname)) = 0;
            % spike window 2
            [filtvars.baseline2,spikes2] = separate_spikes(thisv,bin_opts.spike_filter_window2);
            filtvars.spikes_noise2 = spikes2; filtvars.spikes_noise2(spikes2>bin_opts.small_spike.(vname)) = 0;
            filtvars.spikes2 = spikes2; filtvars.spikes2(spikes2<=bin_opts.small_spike.(vname)|spikes2>bin_opts.big_spike.(vname)) = 0;
            filtvars.spikes_big2 = spikes2; filtvars.spikes_big2(spikes2<=bin_opts.big_spike.(vname)) = 0;
            filtvars.spikes_small2 = spikes2; filtvars.spikes_small2(spikes2<=bin_opts.small_spike.(vname)|spikes2>bin_opts.medium_spike.(vname)) = 0;
            filtvars.spikes_medium2 = spikes2; filtvars.spikes_medium2(spikes2<=bin_opts.medium_spike.(vname)|spikes2>bin_opts.big_spike.(vname)) = 0;
            filtvnames = fieldnames(filtvars);
            % bin average spike means and counts
            for fvix = 1:length(filtvnames)
                fvname = filtvnames{fvix};
                % bin mean signal
                [~, pc_bins.(float_name).(fvname).(vname)(:,pix), pc_bins.(float_name).nfilt.(vname)(:,pix), ~] = ...
                    binaverage_edges(thisz_filt,filtvars.(fvname),zbin_edges);
                % bin number of spikes
                if ismember(fvname,spike_number_vtypes)
                    nspikes = filtvars.(fvname)>0;
                    [~, nspikes_binned, ~, ~] = binsum_edges(thisz_filt,nspikes,zbin_edges);
                    pc_bins.(float_name).([fvname '_n']).(vname)(:,pix) = nspikes_binned;
                    % get uncertainties for number of spikes
                    [~,nspikes_upper] = poissonUpperBoundChi2(nspikes_binned, 0.05);
                    [~,nspikes_lower] = poissonLowerBoundChi2(nspikes_binned, 0.05);
                    pc_bins.(float_name).uncertainties.([fvname '_n']).(vname).upper.precision(:,pix) = nspikes_upper;
                    pc_bins.(float_name).uncertainties.([fvname '_n']).(vname).lower.precision(:,pix) = nspikes_lower;
                end
            end
            % [~, pc_bins.(float_name).std.(vname)(:,pix), pc_bins.(float_name).nfilt.(vname)(:,pix), ~] = ...
            %     binstd_edges(thisz_filt,filtvars.spikes_med,zbin_edges);
            % [~, pc_bins.(float_name).std_nobig.(vname)(:,pix), pc_bins.(float_name).nfilt.(vname)(:,pix), ~] = ...
            %     binstd_edges(thisz_filt,filtvars.spikes_med_nobig,zbin_edges);

            % spike variances for size calculation
            [~, pc_bins.(float_name).var.(vname)(:,pix), ~, ~] = ...
                binvar_edges(thisz_filt,filtvars.spikes_med,zbin_edges);
            [~, pc_bins.(float_name).var_nobig.(vname)(:,pix), ~, ~] = ...
                binvar_edges(thisz_filt,filtvars.spikes_med_nobig,zbin_edges);

            % Particle size distribution slopes
            if ismember(vname,bin_opts.size_vars)
                % Calculate diameters
                A = filtvars.spikes2/100*bin_opts.V/bin_opts.Q; % cm^2 = m^-1 / 100 * cm^3
                D = 10*sqrt(A*4/pi); % mm = sqrt(cm^2) * 10
                Dmin_PSD_fit = bin_opts.small_bbp_spike_diameter; % mm
                %% loop through depth bins
                for zix = 1:length(zbin_edges)-1
                    gz = is_between(thisz_filt,zbin_edges(zix+[0 1]));
                    if any(gz)
                        % Get PSD slopes and uncertainties
                        [b_hat, ~, ci_b] = fastPSD(D(gz), Dmin_PSD_fit, 0.05);
                        pc_bins.(float_name).PSD_slope.(vname)(zix,pix) = b_hat;
                        pc_bins.(float_name).uncertainties.PSD_slope.(vname).upper.precision(zix,pix) = ci_b(2)-b_hat;
                        pc_bins.(float_name).uncertainties.PSD_slope.(vname).lower.precision(zix,pix) = b_hat - ci_b(1);
                    end
                end
            end
            end
            end
        end
        end
    end

    %% get uncertainties for mean and var
    pc_bins.(float_name) = GLOBESINK_get_spike_uncertainties(pc_bins.(float_name),bin_opts);
    % %%
    % for vix = 1:length(bin_opts.size_vars)
    %     vname = bin_opts.size_vars{vix};
    %     if isfield(pc_bins.(float_name).total,vname)
    %     for vtix = 1:length(spike_uncertainty_vtypes)
    %         %%
    %         vtype = spike_uncertainty_vtypes{vtix};
    % 
    %         bbp_measured = pc_bins.(float_name).(vtype).(vname);
    %         c_bins.(float_name).(vtype).(vname);
    %         b_hat = pc_bins.(float_name).PSD_slope.(vname);
    %         b_lo_fit = b_hat - pc_bins.(float_name).uncertainties.PSD_slope.(vname).lower.precision;
    %         b_hi_fit = b_hat + pc_bins.(float_name).uncertainties.PSD_slope.(vname).upper.precision;
    % 
    %         Dmin = Diameter_limits.(vtype)(1); Dmax = Diameter_limits.(vtype)(2);
    %         nsamples = pc_bins.(float_name).nfilt.(vname);
    %         switch vtype
    %             case 'spikes_med'
    %                 nparticles = pc_bins.(float_name).spikes2_n.(vname) + pc_bins.(float_name).spikes_big2_n.(vname);
    %             case 'spikes_med_nobig'
    %                 nparticles = pc_bins.(float_name).spikes2_n.(vname);
    %             otherwise
    %                 nparticles = pc_bins.(float_name).([vtype '_n']).(vname);
    %         end
    %         [n_hi,nmiss_hi] = poissonUpperBoundChi2(nparticles, 0.05); [n_lo,nmiss_lo] = poissonLowerBoundChi2(nparticles, 0.05);
    % 
    %         % intersection with literature bounds
    %         b_lit_range = [3.3 4.5];
    %         b_lo = max(b_lo_fit,b_lit_range(1)); b_hi = min(b_hi_fit,b_lit_range(2));
    %         b_mid = (b_lo+b_hi)/2;
    % 
    %         [dA_hi, dVar_hi] = psdAreaStats(Dmin, Dmax, b_lo, nmiss_hi./nsamples, bin_opts.V); % upper add
    %         [dA_lo, dVar_lo] = psdAreaStats(Dmin, Dmax, b_lo, nmiss_lo./nsamples, bin_opts.V); % lower add
    %         [A_hi, Var_hi] = psdAreaStats(Dmin, Dmax, b_lo, n_hi./nsamples, bin_opts.V); % upper bound
    %         [A_lo, Var_lo] = psdAreaStats(Dmin, Dmax, b_hi, n_lo./nsamples, bin_opts.V); % lower bound
    % 
    %         % convert area concentration (mm^2/ml) to bbp (m^-1)
    %         CF = bin_opts.Q; % conversion factor for units and Qbb
    %         dbbp_hi = dA_hi * CF; dbbp_lo = dA_lo * CF;
    %         bbp_hi = A_hi * CF; bbp_lo = A_lo * CF;
    %         % get alternative lower bounds
    %         dbbp_lo2 = bbp_measured-bbp_lo;
    %         disp([float_name ' ' vname vtype ' altlow ratio – ' num2str(sum(dbbp_lo2(:)<dbbp_lo(:))) ':' num2str(sum(dbbp_lo2(:)>=dbbp_lo(:)))])
    %         dbbp_lo = min(dbbp_lo,dbbp_lo2);
    %         pc_bins.(float_name).uncertainties.(vtype).(vname).upper.precision = dbbp_hi;
    %         pc_bins.(float_name).uncertainties.(vtype).(vname).lower.precision = dbbp_lo;
    %         switch vtype
    %             case {'spikes_med','spikes_med_nobig'}
    %                 vt_suffix = vtype(11:end);
    %                 bbp_var_measured = pc_bins.(float_name).(['var' vt_suffix]).(vname);
    %                 % convert area concentration variance (µm/ml)^2 to bbp variance (m^-1)^2
    %                 dVar_bbp_hi = dVar_hi * CF^2; dVar_bbp_lo = dVar_lo * CF^2;
    %                 Var_bbp_hi = Var_hi * CF^2; Var_bbp_lo = Var_lo * CF^2;
    %                 % get alternative lower bounds
    %                 dVar_bbp_lo2 = bbp_var_measured-Var_bbp_lo;
    %                 disp([float_name ' ' vname vtype ' altlow var ratio – ' num2str(sum(dVar_bbp_lo2(:)<dVar_bbp_lo(:))) ':' num2str(sum(dVar_bbp_lo2(:)>=dVar_bbp_lo(:)))])
    %                 dVar_bbp_lo = min(dVar_bbp_lo,dVar_bbp_lo2);
    %                 pc_bins.(float_name).uncertainties.(['var' vt_suffix]).(vname).upper.precision = dVar_bbp_hi;
    %                 pc_bins.(float_name).uncertainties.(['var' vt_suffix]).(vname).lower.precision = dVar_bbp_lo;
    %         end
    %     end
    %     end
    % end
    %% get mean diameters
    size_suffices = {'','_nobig'};
    pc_bins.(float_name) = GLOBESINK_calculate_mean_ESD(pc_bins.(float_name),bin_opts,size_suffices);
    % for vix = 1:length(bin_opts.size_vars)
    %     vname = bin_opts.size_vars{vix};
    %     if isfield(biofloat.(float_name),vname)
    %         for size_ix = 1:length(size_suffices)
    %             size_suffix = size_suffices(size_ix);
    %             this_var = (pc_bins.(float_name).(['var' size_suffix]).(vname)-bin_opts.bbp_var_blank);
    %             this_mean = (pc_bins.(float_name).(['baseline_med' size_suffix]).(vname)+pc_bins.(float_name).(['spikes_med' size_suffix]).(vname)-bin_opts.bbp_blank);
    % 
    %             this_var_upper = this_var + pc_bins.(float_name).uncertainties.(['var' size_suffix]).(vname).upper.precision;
    %             this_var_lower = this_var - pc_bins.(float_name).uncertainties.(['var' size_suffix]).(vname).lower.precision;
    %             this_mean_upper = this_mean + pc_bins.(float_name).uncertainties.(['spikes_med' size_suffix]).(vname).upper.precision;
    %             this_mean_lower = this_mean - pc_bins.(float_name).uncertainties.(['spikes_med' size_suffix]).(vname).lower.precision;
    % 
    %             size = sqrt(this_var./this_mean*bin_opts.V/bin_opts.Q/100)*10000;
    %             size_upper = sqrt(this_var_upper./this_mean_upper*bin_opts.V/bin_opts.Q/100)*10000;
    %             size_lower = sqrt(this_var_lower./this_mean_lower*bin_opts.V/bin_opts.Q/100)*10000;
    % 
    %             pc_bins.(float_name).(['D_mean' size_suffix]).(vname) = size;
    %             pc_bins.(float_name).uncertainties.(['D_mean' size_suffix]).(vname).upper.precision = size_upper - size;
    %             pc_bins.(float_name).uncertainties.(['D_mean' size_suffix]).(vname).lower.precision = size - size_lower;
    %         end
    %     end
    % end

    else
        pc_bins = [];
    end
end
