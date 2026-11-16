function biofloat_cdom_QC = GLOBESINK_cdom_data_QC(biofloat,QC_plot_folder,plot_QC_tz_sections,biofloat_cdom_QC_old,recalc_cdom_baseline)
% biofloat_cdom_QC = GLOBESINK_cdom_data_QC(biofloat,QC_plot_folder,plot_QC_tz_sections,biofloat_cdom_QC_old);

% GLOBESINK_cdom_data_QC.m

% sets flags for spikes from animals based on magnitude of CDOM spikes
% and/or magnitude of bbp spikes. Extends flag to nearby points.

% clear
% spike_filter_window = 15;
% UVP_data_folder = [home_folder 'BiogeochemicalArgo/UVP_data/'];
% floatdata_filename = [UVP_data_folder 'UVP_BGC_data_w' num2str(spike_filter_window) '.mat'];

% floatdata_filename = [home_folder 'BiogeochemicalArgo/data_Matlab_format/EmilyOsborne_floats.mat'];

% load(floatdata_filename)

if nargin<5
    recalc_cdom_baseline = 0;
    if nargin<4
        biofloat_cdom_QC_old = [];
        if nargin<3
            plot_QC_tz_sections = 1;
        end
    end
end
%%
recalc_QC = 1;

% calculating the cdom baseline takes a long time, so this can be set to
% zero so that baseline is not re-calculated if it already exists
% process_CDOM = 0;
% recalc_cdom_baseline = 0;

% keep this as zero for now
process_new_downloads_only = 0;

% max_fraction_bad_bbp_per_profile = 0.5; % <=== LOWER EXCLUDES MORE PROFILES
% % set meter distance between near spikes (larger number will find more "bad" spikes)
% vertical_distance_between_big_spikes = 75; % m
% % set number of profiles between near spikes (larger number will find more "bad" spikes)
% number_of_profiles_between_big_spikes = 2; % m
% % set meter distance to exclude data because they are near a spike
% bad_bbp_spike_vertical_buffer_m = 50; % meters
% number_of_nearby_spikes_to_consider_bad = 2; % lower excludes more spikes
% big_spike_threshold = 7e-3; % inverse meters. lower excludes more spikes

%%

if process_new_downloads_only
    float_names = new_downloads_cellarray{rix};
else
    float_names = fieldnames(biofloat);
end
n_floats = length(float_names);
if n_floats>1
    disp('file contains multiple floats')
    float_names
    disp(['only processing ' float_names{1}])
end
%% LOOP THROUGH EACH FLOAT IN THE REGION
for fix = 1%:n_floats
    %%
    float_name = float_names{fix};
    disp(float_name)
    t = biofloat.(float_name).M_TIME; % TIME
    z = biofloat.(float_name).PRES; % DEPTH (PRESSURE)
    bbp = biofloat.(float_name).BBP700; % BACKSCATTERING
    is_negative = bbp<0;
    bbp(is_negative) = nan;
    [bbp_baseline,bbp_spikes_median] = separate_spikes_median(bbp,5); % SEPARATE BACKSCATTERING SPIKES FROM BASELINE
    [bbp_baseline_minmax,bbp_spikes] = separate_spikes(bbp,15); % SEPARATE BACKSCATTERING SPIKES FROM BASELINE
    chl = biofloat.(float_name).CHLA; % CHLOROPHYLL A
%     [chl_baseline,chl_spikes] = separate_spikes_median(chl,11); % SEPARATE CHL SPIKES FROM BASELINE
    [chl_baseline,chl_spikes] = separate_spikes(chl,15); % SEPARATE CHL SPIKES FROM BASELINE
    pnum = biofloat.(float_name).CYCLE_NUMBER;
    if isfield(biofloat.(float_name),'is_ascent')
        pnum(~biofloat.(float_name).is_ascent) = pnum(~biofloat.(float_name).is_ascent)-0.5;
    end
    [profile_numbers,~,profile_ixs] = unique(pnum);

    vname = 'BBP700';
    v = biofloat.(float_name).(vname);
    notnan = ~isnan(v);
    all_diffs = abs(diff(v(notnan)));
%     res_quantiles = quantile(all_diffs(all_diffs>median(all_diffs/10)),[0.01 0.02 0.05 0.1 0.2 0.3 0.5]);
%     min_res = res_quantiles(2);
    min_res = quantile(all_diffs,0.3);
    min_resolutions.(float_name).(vname) = min_res;
    %%
if recalc_QC
    % if process_CDOM % not used right now
        if isfield(biofloat.(float_name),'CDOM')
        cdom = biofloat.(float_name).CDOM; % RAW CDOM SIGNAL
        % if any(~isnan(biofloat.(float_name).BBP532))||rix>6 % SOME FLOATS HAVE A SECOND WAVELENGTH OF BACKSCATTERING AND NO CDOM, SO CDOM SHOULD BE NAN
        %     cdom = nan(size(t));
        % end


        cdom_baseline = nan(size(cdom)); % INITIALIZE CDOM BASELINE
        notnan = ~isnan(cdom);

        if recalc_cdom_baseline || isempty(biofloat_cdom_QC_old) || ...
                ~isfield(biofloat_cdom_QC_old,float_name) || ...
                ~isfield(biofloat_cdom_QC_old.(float_name),'cdom_baseline') % || length(b_old.biofloat.(float_name).profile_num)>length(biofloat.(float_name).profile_num)
            % IF THE ABOVE CONDITIONS ARE MET, START CALCULATING THE CDOM
            % BASELINE AT THE BEGINNING OF THE FILE
            cd_bl_start_ix = 1;
        else
            % OTHERWISE START CALCULATING THE CDOM
            % BASELINE AT THE END OF THE PREVIOUS FILE FILE
            pnum_old = biofloat_cdom_QC_old.(float_name).pnum;
            cdom_baseline(1:length(pnum_old)) = biofloat_cdom_QC_old.(float_name).cdom_baseline;

            if length(pnum_old) == length(pnum)
                cd_bl_start_ix = length(pnum_old)+1;
            else
                % start from last profile (redoing last one)
                cd_bl_start_ix = find(pnum >= max(pnum_old),1);
            end
        end
        %
        if any(~isnan(cdom))
            for ii = cd_bl_start_ix:length(cdom)
                if notnan(ii)
                    this_prof = profile_ixs(ii); this_z = z(ii);

                    % SET RANGE OF POINTS NEARBY FOR CDOM BASELINE CALC
                    near_this_point = abs(profile_ixs - this_prof)<=1 & abs(z-this_z) <= 35; % ±1 PROFILE END 35 METERS

                    % BASELINE IS THE MEDIAN OF ALL POINTS WITHIN 1 PROFILE AND 35 METERS UP OR DOWN
                    cdom_baseline(ii) = median(cdom(near_this_point&notnan));
                end
            end


            [cdom_baseline_hf,cdom_spikes_hf] = separate_spikes_median(cdom,11); % initial spike test
            cdom_baseline_new = cdom_baseline;
            cdom_baseline_new(cdom_baseline_hf<cdom_baseline_new) = ...
                cdom_baseline_hf(cdom_baseline_hf<cdom_baseline_new);
            %         cdom_baseline(cdom_baseline>max(100,quantile(cdom_baseline,0.9)+20)) = quantile(cdom_baseline,0.9);
            cdom_spikes = cdom - cdom_baseline_new;

            % SET THRESHOLD FOR CDOM SPIKE
            min_spike = 2*diff(quantile(cdom_spikes,[0.1 0.9]));
            %%

            % IS THIS POINT A CDOM SPIKE (INITIAL TEST)
            is_cdom_spike_initial = cdom_spikes_hf >= min_spike & z > 10;% | cdom > nanmedian(cdom)+20;
            is_near_cdom_spike = false(size(is_cdom_spike_initial));
            is_cdom_spike = false(size(is_cdom_spike_initial));
            cdom_spike_ixs = find(is_cdom_spike_initial);
            %%
            for ii = 1:length(cdom_spike_ixs)
                this_ix = cdom_spike_ixs(ii);
                this_prof = profile_ixs(this_ix); this_z = z(this_ix);
                near_this_spike = profile_ixs == this_prof & abs(z-this_z) <= 30;
                near_this_spike2 = profile_ixs == this_prof & abs(z-this_z) <= 75;
                %             near_this_spike3 = abs(profile_ixs - this_prof)<=2 & abs(z-this_z) <= 75;

                % IS THIS POINT A CDOM SPIKE (FINAL TEST)
                if (z(this_ix) > 250 && cdom_spikes(this_ix) > 0.1) || cdom_spikes(this_ix) > 1 %|| ...
                        %(cdom_spikes(this_ix) > max(-min(cdom_spikes(near_this_spike2&z>10))*3,0.3))
                    %             if cdom_spikes(this_ix) > -quantile(cdom_spikes(near_this_spike2&z>10),0.1)*3
                    %             if cdom_spikes(this_ix) > 20 || ~any(cdom_spikes(near_this_spike)<-10)
                    is_cdom_spike(this_ix) = true;
                    is_near_cdom_spike(near_this_spike) = true;
                end
            end
        else
            cdom_baseline_new = cdom_baseline;
            cdom_spikes = cdom;
            is_near_cdom_spike = false(size(cdom));
            is_cdom_spike = false(size(cdom));
        end
        biofloat_cdom_QC.(float_name).pnum = pnum;
        biofloat_cdom_QC.(float_name).is_near_cdom_spike = is_near_cdom_spike;
        biofloat_cdom_QC.(float_name).cdom_baseline =  cdom_baseline;
        biofloat_cdom_QC.(float_name).cdom_baseline2 =  cdom_baseline_new;
        biofloat_cdom_QC.(float_name).is_cdom_spike =  is_cdom_spike;
        end
    % end
else
    biofloat_cdom_QC = biofloat_cdom_QC_old;
end
    if plot_QC_tz_sections && isfield(biofloat.(float_name),'CDOM') && ...
            ~isempty(biofloat_cdom_QC) && any(~isnan(biofloat_cdom_QC.(float_name).cdom_baseline))
    %% MAKE SOME PLOTS
    notbad = ~biofloat_cdom_QC.(float_name).is_near_cdom_spike;

    figure(fix);clf
    sp(1) = subplot(4,3,3);hold on
    plot3c(t,z,cdom_baseline_new,'.');axis ij; view(2)
    clim(quantile(cdom_baseline_new,[0.02 0.98])+[-0.1 0.1])
    title(float_name)
    cbarlabel('CDOM baseline');
    sp(2) = subplot(4,3,6);hold on
    plot3c(t,z,cdom_spikes,'.');axis ij; view(2)
    clim([0 3])
    cbarlabel('CDOM spikes');
    sp(3) = subplot(4,3,9);hold on
    plot3c(t(notbad),z(notbad),cdom_baseline_new(notbad),'.');axis ij; view(2)
    clim(quantile(cdom_baseline_new,[0.02 0.98])+[-0.1 0.1])
    title(float_name)
    cbarlabel('CDOM baseline cleaned');
    sp(4) = subplot(4,3,12);hold on
    plot3c(t(notbad),z(notbad),cdom_spikes(notbad),'.');axis ij; view(2)
    clim([0 5])
    cbarlabel('CDOM spikes cleaned');

    sp(5) = subplot(4,3,2);hold on
    plot3c(t,z,chl_baseline,'.');axis ij; view(2)
    title('CDOM spike removal')
    cbarlabel('chl baseline');
    sp(6) = subplot(4,3,5);hold on
    plot3c(t,z,chl_spikes,'.');axis ij; view(2)
    cbarlabel('chl spikes');
    sp(7) = subplot(4,3,8);hold on
    plot3c(t(notbad),z(notbad),chl_baseline(notbad),'.');axis ij; view(2)
    title(float_name)
    cbarlabel('chl baseline');
    sp(8) = subplot(4,3,11);hold on
    plot3c(t(notbad),z(notbad),chl_spikes(notbad),'.');axis ij; view(2)
    cbarlabel('chl spikes');

    sp(9) = subplot(4,3,1);hold on
    plot3c(t,z,bbp_baseline,'.');axis ij; view(2)
    title(float_name)
    cbarlabel('bbp baseline');
    sp(10) = subplot(4,3,4);hold on
    plot3c(t,z,bbp_spikes,'.');axis ij; view(2)
    cbarlabel('bbp spikes');
    sp(11) = subplot(4,3,7);hold on
    plot3c(t(notbad),z(notbad),bbp_baseline(notbad),'.');axis ij; view(2)
    cbarlabel('bbp baseline cleaned');
    sp(12) = subplot(4,3,10);hold on
    plot3c(t(notbad),z(notbad),bbp_spikes(notbad),'.');axis ij; view(2)
    cbarlabel('bbp spikes cleaned');
%
%     for fix = 1:length(float_names)
%         figure(fix)
    for vix = 1:12
        subplot(sp(vix))
        if vix >=9
        clim([0 2e-3])
%         better_cmap_black_gray;
        set_cmap_red_pale_dark_bright;
        elseif vix >=5
            clim([0 2])
            set_cmap_green_pale_dark_bright;
        else
            better_cmap_black_gray;
        end
        ylim([0 2000])
        xlim([min(t)-1 max(t)+1])
        datetick('x','keeplimits')
    end
%     if plot_individual_maps
        set(gcf,'paperunits','inches','papersize',[20 10],'paperposition',[0 0 20 10])
%         set(gcf,'paperunits','inches','papersize',[7 2*length(ind_float_vnames)+3],'paperposition',[0 0 7  2*length(ind_float_vnames)+3])
        print('-dpng',[QC_plot_folder float_name '_cdom_QC.png'])
%     end
%     figure(30);hold on
%     plot(biofloat.(float_names{fix}).LONGITUDE,biofloat.(float_names{fix}).LATITUDE)
%     end
    end
%%
end

