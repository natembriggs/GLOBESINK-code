function biofloat_QC = GLOBESINK_bbp_data_QC(biofloat,QC_plot_folder,plot_QC_depth_sections,plot_QC_tz_sections)
% biofloat_QC = GLOBESINK_bbp_data_QC(biofloat,QC_plot_folder,plot_QC_depth_sections,plot_QC_tz_sections);

% GLOBESINK_bbp_data_QC.m

% sets flags for spikes from animals based on magnitude of CDOM spikes
% and/or magnitude of bbp spikes. Extends flag to nearby points.

% clear
% spike_filter_window = 15;
% UVP_data_folder = [home_folder 'BiogeochemicalArgo/UVP_data/'];
% floatdata_filename = [UVP_data_folder 'UVP_BGC_data_w' num2str(spike_filter_window) '.mat'];

% floatdata_filename = [home_folder 'BiogeochemicalArgo/data_Matlab_format/EmilyOsborne_floats.mat'];

% load(floatdata_filename)

if nargin<4
    plot_QC_tz_sections = 1;
    if nargin<3
        plot_QC_depth_sections = 0;
    end
end
%%
recalc_QC = 1;

% calculating the cdom baseline takes a long time, so this can be set to
% zero so that baseline is not re-calculated if it already exists

% keep this as zero for now
process_new_downloads_only = 0;

max_fraction_bad_bbp_per_profile = 0.85; % <=== LOWER EXCLUDES MORE PROFILES
% set meter distance between near spikes (larger number will find more "bad" spikes)
vertical_distance_between_big_spikes = 75; % m
% set number of profiles between near spikes (larger number will find more "bad" spikes)
number_of_profiles_between_big_spikes = 2; 
% set meter distance to exclude data because they are near a spike
bad_bbp_spike_vertical_buffer_m = 50; % meters
number_of_nearby_spikes_to_consider_bad = 2; % lower excludes more spikes
big_spike_threshold = 7e-3; % inverse meters. lower excludes more spikes

argo_greylist = readtable('ar_greylist.txt');
argo_greylist.PARAMETER_NAME = categorical(argo_greylist.PARAMETER_NAME);
argo_greylist = argo_greylist(argo_greylist.PARAMETER_NAME==categorical({'BBP700'}),:);
argo_greylist.start_mtime = datenum(num2str(argo_greylist.START_DATE),'yyyymmdd');
argo_greylist.end_mtime = inf(height(argo_greylist),1);
argo_greylist.end_mtime(~isnan(argo_greylist.END_DATE)) = datenum(num2str(argo_greylist.END_DATE(~isnan(argo_greylist.END_DATE))),'yyyymmdd');
%%
argo_greylist2 = readtable('GLOBESINK_bbp_greylist.xlsx');
argo_greylist2.PLATFORM_CODE = argo_greylist2.float_WMO;
argo_greylist2.start_mtime = datenum(argo_greylist2.start_date);
argo_greylist2.end_mtime = datenum(argo_greylist2.end_date);
argo_greylist2.end_mtime(isnan(argo_greylist2.end_mtime)) = inf;

argo_greylist_combined = concatonate_tables_robust(argo_greylist(:,{'PLATFORM_CODE','start_mtime','end_mtime'}),argo_greylist2(:,{'PLATFORM_CODE','start_mtime','end_mtime'}));
%%

if process_new_downloads_only
    float_names = new_downloads_cellarray{rix};
else
    float_names = fieldnames(biofloat);
end
n_floats = length(float_names);
%% LOOP THROUGH EACH FLOAT IN THE REGION
for fix = 1:n_floats
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

    %% BBP SPIKES
    % set threshold for large spike height

    is_big_bbp_spike = bbp_spikes > big_spike_threshold;% | cdom > nanmedian(cdom)+20; 
    is_near_big_bbp_spike = false(size(is_big_bbp_spike));
    big_bbp_spike_ixs = find(is_big_bbp_spike);
    for ii = 1:length(big_bbp_spike_ixs)
        this_ix = big_bbp_spike_ixs(ii);
        this_prof = profile_ixs(this_ix); this_z = z(this_ix);

        near_this_spike2 = abs(profile_ixs - this_prof)<=number_of_profiles_between_big_spikes & abs(z-this_z) <= vertical_distance_between_big_spikes; 
        near_this_spike = profile_ixs == this_prof & abs(z-this_z) <= bad_bbp_spike_vertical_buffer_m;
        if sum(is_big_bbp_spike(near_this_spike2))>=number_of_nearby_spikes_to_consider_bad
            is_near_big_bbp_spike(near_this_spike) = true;
        end
    end
    %% BBP BASELINE – more complex code. doesn't need adjusting for now
%             [bbp_baseline,spikes_med] = separate_spikes_median(v,11);
%             [baseline2,spikes2] = separate_spikes(v,11);
            z_edges = [0:10:250 275:25:400 425:50:1025 1125:100:2025]; z_midpoints = midpoints(z_edges);
            zwidths_wide = 50*ones(size(z_midpoints));
            zwidths_wide(z_midpoints>250) = 100;
            zwidths_wide(z_midpoints>1000) = 300;
            p_window = min(21,length(profile_numbers)); % profiles
            p_starts = min(1:length(profile_numbers),length(profile_numbers)-p_window+1);
            p_ends = max(1:length(profile_numbers),p_window);
            p_midpoints = 1:length(profile_numbers);
%             p_starts = floor(min(profile_ixs)):ceil(max(profile_ixs))-p_window+1;
%             p_midpoints = p_starts + (p_window-1)/2;
            t_midpoints = nan(size(p_midpoints));
            for pix = 1:length(p_midpoints)
                t_midpoints(pix) = median(t(~isnan(t)&profile_ixs==p_midpoints(pix)));
                if pix>1 && ismember(t_midpoints(pix),t_midpoints(1:pix-1))
                    t_midpoints(pix) = nan;
                end
            end
            pix_edges = 0.5:length(profile_numbers)+0.5;
            in_range = ~(bbp_baseline>0.03|(bbp_baseline>0.004&z>200)|(bbp_baseline>0.002&z>500));
            [pix_mat.(vname),z_mat.(vname),med_mat.(vname),n_mat.(vname)] = binmedian_2D(profile_ixs(in_range),z(in_range),bbp_baseline(in_range),pix_edges,z_edges);
            
            %%
            [mat_m,mat_n] = size(med_mat.(vname));
            med_mat_smoothed.(vname) = nan(mat_m,mat_n);
            for zix = 1:mat_m
                thisg = ~isnan(med_mat.(vname)(zix,:));
                if any(thisg)
                    thisv = med_mat.(vname)(zix,thisg);
%                     thisv_smoothed = running_median(thisv,5);
%                     thisv_smoothed([1 2 end-1 end]) = thisv_smoothed([3 3 end-2 end-2]);
                    if length(thisv)>1
                        thisv_smoothed = running_median(thisv,3);
                        thisv_smoothed([1 end]) = thisv_smoothed([2 end-1]);
                    else
                        thisv_smoothed = thisv;
                    end
                    med_mat_smoothed.(vname)(zix,thisg) = thisv_smoothed;
                end
            end
            med_mat_padded.(vname) = nan(mat_m+1,mat_n+1);
            med_mat_smoothed_padded.(vname) = nan(mat_m+1,mat_n+1);
            med_mat_padded.(vname)(1:mat_m,1:mat_n) = med_mat.(vname);
            med_mat_smoothed_padded.(vname)(1:mat_m,1:mat_n) = med_mat_smoothed.(vname);
            %%
            plot_smoothing_step = 0;
            if plot_smoothing_step
                figure(20+fix);clf;
                subplot(2,1,1);hold on
                %             pcolor(pix_mat.(vname),z_mat.(vname),med_mat.(vname));axis ij; shading flat
                pcolor(pix_edges,z_edges,med_mat_padded.(vname));axis ij; shading flat
                caxis([0 quantile(med_mat.(vname)(:),0.95)*3])
                ylim([min(med_mat.(vname)(:)) 2010])
                cbarlabel(rem_(vname));
                better_cmap_black_gray;
                subplot(2,1,2);hold on
                %             pcolor(pix_mat.(vname),z_mat.(vname),med_mat.(vname));axis ij; shading flat
                pcolor(pix_edges,z_edges,med_mat_smoothed_padded.(vname));axis ij; shading flat
                caxis([0 quantile(med_mat.(vname)(:),0.95)*3])
                ylim([min(med_mat.(vname)(:)) 2010])
                cbarlabel(rem_(vname));
                better_cmap_black_gray;
            end
%%
            smooth_mat.(vname).med = nan(length(z_edges)-1,length(p_starts));
            smooth_mat.(vname).upper_q = nan(length(z_edges)-1,length(p_starts));
            smooth_mat.(vname).lower_q = nan(length(z_edges)-1,length(p_starts));
            smooth_mat.(vname).upper_bound = nan(length(z_edges)-1,length(p_starts));
            smooth_mat.(vname).lower_bound = nan(length(z_edges)-1,length(p_starts));
            is_bad = false(size(bbp_baseline));
            is_high = false(size(bbp_baseline));
            is_low = false(size(bbp_baseline));
            %%
            for zix = 1:length(z_edges)-1
                %%
                zwidth_wide = zwidths_wide(zix);

                gz = notnan&is_between(z,z_edges(zix+[0 1]));
                gz_broad = notnan&is_between(z,z_midpoints(zix)+zwidth_wide*[-1 1]);
                gz_broad_medmat = ~isnan(med_mat.(vname))&is_between(z_mat.(vname),z_midpoints(zix)+zwidth_wide*[-1 1]);
                zbin_ixs = max(zix-4,1):min(zix+4,mat_m);
                if any(gz)
                    for tix = 1:length(p_starts)
%                         gt = gz & profile_ixs >= p_starts(tix) & profile_ixs <= p_starts(tix)+p_window-1 & profile_ixs ~= p_midpoints(tix);
                        gt_broad = gz_broad & profile_ixs >= p_starts(tix) & profile_ixs <= p_ends(tix) & profile_ixs ~= p_midpoints(tix);
%                         gt_broad_medmat = gz_broad_medmat & profile_ixs >= p_starts(tix) & profile_ixs <= p_starts(tix)+p_window-1 & profile_ixs ~= p_midpoints(tix);
                        tbin_ixs = max(tix-4,1):min(tix+4,mat_n);
                        this_medmat = med_mat_smoothed.(vname)(zbin_ixs,tbin_ixs);
%                         sum(gt);
%                         if sum(gt_broad)>40
%                             qs = quantile(bbp_baseline(gt_broad),[0.05 0.5 0.95]);
                        if sum(~isnan(this_medmat(:)))>35
                            qs = quantile(this_medmat(~isnan(this_medmat)),[0.05 0.5 0.95]);
                            smooth_mat.(vname).lower_q(zix,tix) = qs(1);
                            smooth_mat.(vname).med(zix,tix) = qs(2);
                            smooth_mat.(vname).upper_q(zix,tix) = qs(3);
                        end
                    end
                    upper_int = smooth_mat.(vname).upper_q(zix,:) - smooth_mat.(vname).med(zix,:);
                    lower_int = smooth_mat.(vname).med(zix,:) - smooth_mat.(vname).lower_q(zix,:);
                    ul_diff = smooth_mat.(vname).upper_q(zix,:) - smooth_mat.(vname).lower_q(zix,:);
%                     smooth_mat.(vname).upper_bound(zix,:) = smooth_mat.(vname).upper_q(zix,:)+ul_diff*0.9+min_res*5;
%                     smooth_mat.(vname).lower_bound(zix,:) = smooth_mat.(vname).lower_q(zix,:)-ul_diff*0.9-min_res*5;
                    smooth_mat.(vname).upper_bound(zix,:) = smooth_mat.(vname).upper_q(zix,:)+max(upper_int*1.8,ul_diff*0.9)+min_res*5;
                    smooth_mat.(vname).lower_bound(zix,:) = smooth_mat.(vname).lower_q(zix,:)-lower_int*1.8-min_res*5;
                    gbounds = ~isnan(smooth_mat.(vname).upper_bound(zix,:))&~isnan(t_midpoints);
                    if sum(gbounds)<1
                        upper_interp = Inf*ones(size(t)); lower_interp = -Inf*ones(size(t));
                    elseif length(t_midpoints)==1 || sum(gbounds)==1
                        upper_interp = smooth_mat.(vname).upper_bound(zix,gbounds)*ones(size(t));
                        lower_interp = smooth_mat.(vname).lower_bound(zix,gbounds)*ones(size(t));
                    elseif sum(gbounds)>1
                        upper_interp = interp1(t_midpoints(gbounds),smooth_mat.(vname).upper_bound(zix,gbounds),t,'nearest','extrap');
                        lower_interp = interp1(t_midpoints(gbounds),smooth_mat.(vname).lower_bound(zix,gbounds),t,'nearest','extrap');
                    end
                    this_high = gz&(bbp_baseline>upper_interp);
                    is_high = is_high|this_high;
                    this_low = gz&(bbp_baseline<lower_interp);
                    is_low = is_low|this_low;
                    this_bad = gz&(bbp_baseline>upper_interp | bbp_baseline<lower_interp);
                    is_bad = is_bad|this_bad;
                    %%
                    % plot_QC_depth_sections = 1;
                    if plot_QC_depth_sections
                        %%
                        figure(100);clf;hold on
                        plot(t(gz_broad),bbp_baseline(gz_broad),'.','color',[0.7 0.7 0.7])
                        plot(t(gz),bbp_baseline(gz),'b.')
                        plot(t(this_bad),bbp_baseline(this_bad),'ro')
                        plot(t_midpoints,smooth_mat.(vname).upper_bound(zix,:),'c','linewidth',2)
                        plot(t_midpoints,smooth_mat.(vname).lower_bound(zix,:),'c','linewidth',2)
                        plot(t_midpoints,smooth_mat.(vname).upper_q(zix,:),'k')
                        plot(t_midpoints,smooth_mat.(vname).med(zix,:),'k','linewidth',2)
                        plot(t_midpoints,smooth_mat.(vname).lower_q(zix,:),'k')
                        title(rem_([float_name '; z = ' num2str(z_edges(zix)) '-' num2str(z_edges(zix+1)) ' m']))
                        ylabel([rem_(vname) ' baseline'])
%                         ylim([min(smooth_mat.(vname).lower_bound(zix,:)*1.25-smooth_mat.(vname).upper_bound(zix,:)*.25) max(smooth_mat.(vname).upper_bound(zix,:))*1.7])
                        datetick('x')
%                         xlabel('days since 1 Oct 2017')
                        set(gcf,'paperunits','inches','papersize',[7 5],'paperposition',[0 0 7 5])
                        print('-dpng',[home_folder 'BiogeochemicalArgo/plots/QC_plots/bbp_baseline_outliers/QC_' vname '_' float_name '_z' num2str(z_edges(zix)) '-' num2str(z_edges(zix+1)) '.png'])
                    end
%                     figure(7);
%                     if any(this_bad)
%                         plot3(t(this_bad),z(this_bad),ones(sum(this_bad),1)*max(baseline_med),'mo')
%                     end
                end
            end
            %%
%             bad_ixs = find(is_bad);
%             near_bad = is_bad;
%             for ii = 1:length(bad_ixs)
%                 is_near = is_between(t,t(bad_ixs(ii))+[-2 10]/60/24);
%                 if sum(is_bad&is_near)>1
%                     near_bad(is_near) = true;
%                 end
%             end
%             %%
%             big_spike_threshold.drv_gcal_bbp532 = 0.01;
%             big_spike_threshold.drv_gcal_bbp700 = 0.01;
%             big_spike_threshold.drv_gcal_chlorophyll = 10;
%             %
%             is_big_spike.(files{fix}(1:end-4)).(vname) = spikes2>big_spike_threshold.(vname);
%             big_spike_ixs = find(is_big_spike.(files{fix}(1:end-4)).(vname));
%             near_big_spike.(files{fix}(1:end-4)).(vname) = false(size(is_big_spike.(files{fix}(1:end-4)).(vname)));
%             for ii = 1:length(big_spike_ixs)
%                 is_near = is_between(t,t(big_spike_ixs(ii))+[-2 10]/60/24);
%                 if sum(is_big_spike.(files{fix}(1:end-4)).(vname)&is_near)>1
%                     near_big_spike.(files{fix}(1:end-4)).(vname)(is_near) = true;
%                 end
%             end
            is_high_bbp_baseline = is_high;
            is_low_bbp_baseline = is_low|is_negative;
%             is_high_bbp_baseline = is_bad;
%             is_near_high_bbp_baseline = near_bad;    
    
% 
%     is_high_bbp_baseline = bbp_baseline>0.03|(bbp_baseline>0.004&z>200);
    high_bbp_baseline_ixs = find(is_high_bbp_baseline);
    is_near_high_bbp_baseline = is_high_bbp_baseline;
    if any(is_high_bbp_baseline)
        for ii = -80:80
            offset_ixs = high_bbp_baseline_ixs + ii;
            offset_ixs = offset_ixs(offset_ixs>=1&offset_ixs<=length(z));
            orig_ixs = offset_ixs - ii;
            same_prof = profile_ixs(orig_ixs) == profile_ixs(offset_ixs);
            within_80m = abs(z(orig_ixs) - z(offset_ixs))<80;
            if any(same_prof&within_80m)
                is_near_high_bbp_baseline(offset_ixs(same_prof&within_80m)) = ...
                    is_near_high_bbp_baseline(offset_ixs(same_prof&within_80m))|...
                    is_high_bbp_baseline(orig_ixs(same_prof&within_80m));
                %                     is_near_high_bbp_baseline(late_ixs(same_prof&within_15m)) = ...
                %                         is_high_bbp_baseline(early_ixs(same_prof&within_15m))&...
                %                         is_near_high_bbp_baseline(late_ixs(same_prof&within_15m));
            end
        end
    end
    is_high_bbp_baseline = is_high_bbp_baseline|bbp_baseline>0.03|(bbp_baseline>0.004&z>200)|(bbp_baseline>0.002&z>500);
    for pix = 1:length(profile_numbers) % loop through individual profiles
        thisp = pnum == profile_numbers(pix)&~isnan(bbp_baseline);
        if sum(thisp)<10 || ((sum(is_high_bbp_baseline(thisp))/sum(thisp))>max_fraction_bad_bbp_per_profile)
            is_near_high_bbp_baseline(thisp) = true;
        end
        if sum(thisp)<10 || ((sum(is_near_big_bbp_spike(thisp))/sum(thisp))>max_fraction_bad_bbp_per_profile)
            is_near_big_bbp_spike(thisp) = true;
        end
    end
    is_near_high_bbp_baseline = is_near_high_bbp_baseline | is_high_bbp_baseline;
    biofloat_QC.(float_name).is_near_high_bbp_baseline = is_near_high_bbp_baseline;
    biofloat_QC.(float_name).is_near_big_bbp_spike = is_near_big_bbp_spike;


    biofloat_QC.(float_name).is_big_bbp_spike =  is_big_bbp_spike;
    biofloat_QC.(float_name).is_high_bbp_baseline =  is_high_bbp_baseline;
    biofloat_QC.(float_name).is_low_bbp_baseline =  is_low_bbp_baseline;
    is_bad_bbp = is_near_high_bbp_baseline | is_low_bbp_baseline;
    % is_bad_bbp = is_near_big_bbp_spike | is_near_high_bbp_baseline | is_low_bbp_baseline;
    biofloat_QC.(float_name).is_bad_bbp = is_bad_bbp;
    % save([mat_out_folder 'f' float_name(3:end) '_QC.mat'],'biofloat_QC')


    % biofloat_QC.(float_name).bad_Argo_QC_bbp =  ismember(biofloat.(float_name).BBP700_QC,'34');
    % biofloat_QC.(float_name).bad_Argo_profile_bbp =  ismember(biofloat.(float_name).PROFILE_BBP700_QC,'EF');
    % biofloat_QC.(float_name).bad_bbp_in_greylist = false(size(is_big_bbp_spike));
    % % is_bad_bbp = is_bad_bbp | ismember(biofloat.(float_name).BBP700_QC,'34');
    % is_bad_bbp = is_bad_bbp | ismember(biofloat.(float_name).PROFILE_BBP700_QC,'EF');
    % this_grey = argo_greylist_combined.PLATFORM_CODE == str2double(float_name(3:end));
    % if any(this_grey)
    %     minigrey = argo_greylist_combined(this_grey,:);
    %     is_bad_bbp = is_bad_bbp | is_between(t,minigrey.start_mtime,minigrey.end_mtime);
    %     biofloat_QC.(float_name).bad_bbp_in_greylist = is_between(t,minigrey.start_mtime,minigrey.end_mtime);
    % end
    % biofloat_QC.(float_name).is_bad_bbp = is_bad_bbp;

    % save([mat_out_folder 'f' float_name(3:end) '_QC.mat'],'biofloat_QC')
end
    if plot_QC_tz_sections
    %% MAKE SOME PLOTS
    notbad = ~biofloat_QC.(float_name).is_bad_bbp;
%     notbad = ~biofloat_QC.(float_name).is_near_high_bbp_baseline & ~biofloat_QC.(float_name).is_low_bbp_baseline;
%     notbad = ~biofloat_QC.(float_name).is_near_big_bbp_spike & ~biofloat_QC.(float_name).is_near_high_bbp_baseline & ...
%         ~biofloat_QC.(float_name).is_low_bbp_baseline&~is_high_bbp_baseline;
% %     notbad = notbad & ~ismember(biofloat.(float_name).BBP700_QC,'34');
% %     notbad = notbad & ~ismember(biofloat.(float_name).PROFILE_BBP700_QC,'CDEF');
%     this_grey = argo_greylist.PLATFORM_CODE == str2double(float_name(3:end));
%     if any(this_grey)
%         minigrey = argo_greylist(this_grey,:);
%         notbad = notbad & ~is_between(t,minigrey.start_mtime,minigrey.end_mtime);
% %         pass_grey = ~is_between(t,minigrey.start_mtime,minigrey.end_mtime);
%     else
% %         pass_grey = true(size(bbp_baseline));
%     end
    figure(fix);clf
    % if isfield(biofloat.(float_name),'CDOM')
    %     sp(1) = subplot(3,2,1);hold on
    %     plot3c(t,z,cdom_baseline_new,'.');axis ij; view(2)
    %     caxis(quantile(cdom_baseline_new,[0.02 0.98])+[-0.1 0.1])
    %     title(float_name)
    %     cbarlabel('CDOM baseline');
    %     sp(2) = subplot(3,2,2);hold on
    %     plot3c(t,z,cdom_spikes,'.');axis ij; view(2)
    %     caxis([0 5])
    %     cbarlabel('CDOM spikes');
    % else
        sp(1) = subplot(3,2,1);hold on
        plot3c(t,z,chl_baseline,'.');axis ij; view(2)
        title(float_name)
        cbarlabel('chl baseline');
        sp(2) = subplot(3,2,2);hold on
        plot3c(t,z,chl_spikes,'.');axis ij; view(2)
        cbarlabel('chl spikes');
    % end
    sp(3) = subplot(3,2,3);hold on
    plot3c(t,z,bbp_baseline,'.');axis ij; view(2)
%     plot3c(t(pass_grey),z(pass_grey),bbp_baseline(pass_grey),'.');axis ij; view(2)
    title(float_name)
    cbarlabel('bbp baseline');
    sp(4) = subplot(3,2,4);hold on
    plot3c(t,z,bbp_spikes,'.');axis ij; view(2)
%     plot3c(t(pass_grey),z(pass_grey),bbp_spikes(pass_grey),'.');axis ij; view(2)
    cbarlabel('bbp spikes');
    sp(5) = subplot(3,2,5);hold on
    plot3c(t(notbad),z(notbad),bbp_baseline(notbad),'.');axis ij; view(2)
    cbarlabel('bbp baseline cleaned');
    sp(6) = subplot(3,2,6);hold on
    plot3c(t(notbad),z(notbad),bbp_spikes(notbad),'.');axis ij; view(2)
    cbarlabel('bbp spikes cleaned');
%
%     for fix = 1:length(float_names)
%         figure(fix)
    for vix = 1:6
        subplot(sp(vix))
        if vix >=3
        caxis([0 2e-3])
%         better_cmap_black_gray;
        set_cmap_red_pale_dark_bright;
        elseif isfield(biofloat.(float_name),'CDOM')
            better_cmap_black_gray;
        else
            caxis([0 2])
            set_cmap_green_pale_dark_bright;
        end
        ylim([0 2000])
        xlim([min(t)-1 max(t)+1])
        datetick('x','keeplimits')
    end
%     if plot_individual_maps
        set(gcf,'paperunits','inches','papersize',[20 10],'paperposition',[0 0 20 10])
%         set(gcf,'paperunits','inches','papersize',[7 2*length(ind_float_vnames)+3],'paperposition',[0 0 7  2*length(ind_float_vnames)+3])
        print('-dpng',[QC_plot_folder float_name '_BBP700_QC.png'])
%     end
%     figure(30);hold on
%     plot(biofloat.(float_names{fix}).LONGITUDE,biofloat.(float_names{fix}).LATITUDE)
%     end
    end
%%

    %         for ii = 1:3
    %             switch ii
    %                 case 1
    %                     gc = ~is_big_bbp_spike|is_big_bbp_spike;
    %                     filename = ['~/Desktop/remOcean/cdom_flag_test/' float_name '_all'];
    %                 case 2
    %                     gc = ~is_near_cdom_spike;
    %                     filename = ['~/Desktop/remOcean/cdom_flag_test/' float_name '_cdom'];
    %                 case 3
    %                     gc = ~is_near_high_bbp_baseline & ~is_near_big_bbp_spike & ~is_near_cdom_spike;
    %                     filename = ['~/Desktop/remOcean/cdom_flag_test/' float_name '_cdom_bbp'];
    %             end
    %             %         gc = ~is_near_big_bbp_spike;
    %             %         gc = ~is_big_bbp_spike|is_big_bbp_spike;
    %
    %             %         gc = gc | ~gc;
    %
    %             tstart = datenum(2013,7,9);
    %             tend = datenum(2013,7,10);
    %             g = is_between(t,tstart,tend)&~isnan(bbp)&gc;
    %
    %
    % %             figure(1);clf;hold on
    % %             plot(bbp(g),z(g));axis ij
    % %             plot(bbp_spikes(g),z(g));axis ij
    % %
    % %             figure(2);clf;hold on
    % %             plot(cdom(g),z(g));axis ij
    % %             plot(cdom_spikes(g),z(g));axis ij
    % %             %         plot(x(g),running_median(y2(g),3))
    % %
    % %             figure(5);clf;hold on
    % %             x = biofloat.(float_name).PAR(is_between(t,tstart,tend));
    % %             plot(log10(x-min(x)),z(is_between(t,tstart,tend)),'.');axis ij
    % %             %         plot(cdom_spikes(g),z(g));axis ij
    %
    %             x_limits = [min(t) max(t)];
    %
    %             figure(3);clf;hold on
    %             subplot_squish_new(3,2,1);hold on
    %             plot3c(t(gc),z(gc),chl_baseline(gc),'.');axis ij
    %             %         plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             cbarlabel('chl')
    %             caxis([0 10])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             better_cmap_purple_black_gray
    %             datetick('x','keeplimits')
    %
    %             subplot_squish_new(3,2,2);hold on
    %             %         plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             plot3c(t(gc),z(gc),chl_spikes(gc)- max(chl_spikes(gc)),chl_spikes(gc),'.');axis ij
    %             cbarlabel('chl')
    %             caxis([0 1])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             better_cmap_black_gray
    %             datetick('x','keeplimits')
    %
    %             subplot_squish_new(3,2,3);hold on
    %             plot3c(t(gc),z(gc),bbp_baseline(gc),'.');axis ij
    % %             plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             cbarlabel('bbp')
    %             caxis([0 1e-2])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             better_cmap_purple_black_gray
    %             datetick('x','keeplimits')
    %
    %             subplot_squish_new(3,2,4);hold on
    %             plot3c(t(gc),z(gc),bbp_spikes(gc)- max(bbp_spikes(gc)),bbp_spikes(gc),'.');axis ij
    % %             plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             cbarlabel('bbp')
    %             caxis([0 12e-3])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             better_cmap_purple_black_gray
    %             datetick('x','keeplimits')
    %
    %             subplot_squish_new(3,2,5);hold on
    %             plot3c(t(gc),z(gc),cdom_baseline_new(gc),'.');axis ij
    %             %         plot3c(t(gc),z(gc),cdom(gc)- max(cdom(gc)),cdom_baseline(gc),'.');axis ij
    % %             plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             caxis([40 80])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             %         caxis([45 61])
    %             better_cmap_purple_black_gray
    %             cbarlabel('cdom baseline')
    %             datetick('x','keeplimits')
    %
    %             subplot_squish_new(3,2,6);hold on
    %             plot3c(t(gc),z(gc),cdom_spikes(gc)- max(cdom_spikes(gc)),cdom_spikes(gc),'.');axis ij
    %             %         plot3c(t(gc),z(gc),cdom(gc)- max(cdom(gc)),cdom_baseline(gc),'.');axis ij
    % %             plot([tstart tend; tstart tend],[0 0 ; 1000 1000],'m')
    %             caxis([0 40])
    %             ylim([0 1000])
    %             xlim(x_limits)
    %             %         caxis([45 61])
    %             better_cmap_purple_black_gray
    %             cbarlabel('cdom')
    %             datetick('x','keeplimits')
    %
    %
    %             set(gcf,'papersize',[20 15],'paperposition',[0 0 20 15])
    %             print('-dpng',[filename '.png'])
    %         end
end

% save(floatdata_filename,'biofloat')
% 
% %         save([home_folder 'remOcean/data/mat_files_remOcean/' ...
% %             region_code '_floats_flagtest.mat'],'-struct','b','-v7.3')
% %%
% 
% figure(50);clf;hold on
% %%
% test_fname = float_names{2};
% test_daterange = datenum(2022,12,[11 14]);
% % test_daterange = datenum(2021,6,[1 4]);
% % test_daterange = datenum(2021,6,[4 8]);
% 
% x = biofloat.(test_fname).BBP700;
% x2 = separate_spikes(x,7);
% x3 = biofloat.(test_fname).BBP700_baseline;
% y = biofloat.(test_fname).PRES;
% g = ~isnan(x)&is_between(biofloat.(test_fname).M_TIME,test_daterange);
% plot(x(g),y(g),'.');axis ij
% plot(x2(g),y(g));axis ij
% plot(x3(g),y(g));axis ij
