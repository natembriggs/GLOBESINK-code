function biofloat_QC = GLOBESINK_bbp_add_manual_QC(biofloat,biofloat_QC,mat_out_folder,plot_folder,plot_tz_sections)
% biofloat_QC = GLOBESINK_bbp_add_manual_QC(biofloat,biofloat_QC,mat_folder,plot_folder,plot_tz_sections);

% GLOBESINK_bbp_data_QC.m

% sets flags for spikes from animals based on magnitude of CDOM spikes
% and/or magnitude of bbp spikes. Extends flag to nearby points.

% clear
% spike_filter_window = 15;
% UVP_data_folder = [home_folder 'BiogeochemicalArgo/UVP_data/'];
% floatdata_filename = [UVP_data_folder 'UVP_BGC_data_w' num2str(spike_filter_window) '.mat'];

% floatdata_filename = [home_folder 'BiogeochemicalArgo/data_Matlab_format/EmilyOsborne_floats.mat'];

% load(floatdata_filename)

if nargin<5
    plot_tz_sections = 1;
end
%%


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

GLOBESINK_manual_QC_flags = readtable('binned_data_visual_QC_checklist_AF_NB_2025.xlsx');
% GLOBESINK_manual_QC_flags = readtable('binned_data_visual_QC_checklist_NB2.xlsx');
% GLOBESINK_manual_QC_flags = readtable('binned_data_visual_QC_checklist_AF_NB.xlsx');

% disp('only applying manual flags 1-4. Excluding flag 5 (drift accumulation)')
% GLOBESINK_manual_QC_flags = GLOBESINK_manual_QC_flags(GLOBESINK_manual_QC_flags.category<5,:);
%%

% if process_new_downloads_only
%     float_names = new_downloads_cellarray{rix};
% else
    float_names = fieldnames(biofloat_QC);
% end
n_floats = length(float_names);
%% LOOP THROUGH EACH FLOAT IN THE REGION
for fix = 1:n_floats
    %%
    float_name = float_names{fix};
    allNums = regexp(float_name, '\d', 'match'); allNums = [allNums{:}];
    float_WMO = str2double(allNums);
    disp(float_name)
    t = biofloat.(float_name).M_TIME; % TIME
    z = biofloat.(float_name).PRES; % DEPTH (PRESSURE)
    bbp = biofloat.(float_name).BBP700; % BACKSCATTERING
    is_negative = bbp<0;
    bbp(is_negative) = nan;
    spike_window = 5;
% %     [bbp_baseline,bbp_spikes] = separate_spikes_median(bbp,11); % SEPARATE BACKSCATTERING SPIKES FROM BASELINE
    [bbp_baseline,bbp_spikes] = separate_spikes(bbp,spike_window); % SEPARATE BACKSCATTERING SPIKES FROM BASELINE
    chl = biofloat.(float_name).CHLA; % CHLOROPHYLL A
% %     [chl_baseline,chl_spikes] = separate_spikes_median(chl,11); % SEPARATE CHL SPIKES FROM BASELINE
    [chl_baseline,chl_spikes] = separate_spikes(chl,spike_window); % SEPARATE CHL SPIKES FROM BASELINE
    pnum = biofloat.(float_name).CYCLE_NUMBER;
    if isfield(biofloat.(float_name),'is_ascent')
        pnum(~biofloat.(float_name).is_ascent) = pnum(~biofloat.(float_name).is_ascent)-0.5;
    end
%     vname = 'BBP700';
%     v = biofloat.(float_name).(vname);
%     notnan = ~isnan(v);
%     all_diffs = abs(diff(v(notnan)));
% %     res_quantiles = quantile(all_diffs(all_diffs>median(all_diffs/10)),[0.01 0.02 0.05 0.1 0.2 0.3 0.5]);
% %     min_res = res_quantiles(2);
%     min_res = quantile(all_diffs,0.3);
%     min_resolutions.(float_name).(vname) = min_res;
    %%
% if recalc_QC
    is_bad_bbp_auto_baseline = biofloat_QC.(float_name).is_near_high_bbp_baseline | ...
        biofloat_QC.(float_name).is_low_bbp_baseline;
    is_bad_bbp_auto_spikes = biofloat_QC.(float_name).is_near_big_bbp_spike;
    
    % is_bad_bbp_auto = biofloat_QC.(float_name).is_near_big_bbp_spike | biofloat_QC.(float_name).is_near_high_bbp_baseline | ...
    %     biofloat_QC.(float_name).is_low_bbp_baseline;

    biofloat_QC.(float_name).bad_Argo_QC_bbp =  ismember(biofloat.(float_name).BBP700_QC,'34');
    biofloat_QC.(float_name).bad_Argo_profile_bbp =  ismember(biofloat.(float_name).PROFILE_BBP700_QC,'EF');
    biofloat_QC.(float_name).bad_bbp_in_greylist = false(size(is_bad_bbp_auto_baseline));
    biofloat_QC.(float_name).bad_bbp_GLOBESINK_manual = false(size(is_bad_bbp_auto_baseline));
    % is_bad_bbp = is_bad_bbp | ismember(biofloat.(float_name).BBP700_QC,'34');
    % is_bad_bbp = is_bad_bbp | ismember(biofloat.(float_name).PROFILE_BBP700_QC,'EF');
    this_grey = argo_greylist_combined.PLATFORM_CODE == str2double(float_name(3:end));
    if any(this_grey)
        minigrey = argo_greylist_combined(this_grey,:);
        % is_bad_bbp = is_bad_bbp | is_between(t,minigrey.start_mtime,minigrey.end_mtime);
        biofloat_QC.(float_name).bad_bbp_in_greylist = is_between(t,minigrey.start_mtime,minigrey.end_mtime);
    end
    this_QC_flag = GLOBESINK_manual_QC_flags.float_WMO == float_WMO;
    if any(this_QC_flag)
        mini_QC = GLOBESINK_manual_QC_flags(this_QC_flag,:);
        bad_QC = false(size(pnum));
        for qcix = 1:height(mini_QC)
            this_bad_QC = is_between(pnum,mini_QC.from_cycle(qcix),mini_QC.to_cycle(qcix)+1);
            if ~isnan(mini_QC.from_depth(qcix))
                this_bad_QC = this_bad_QC & is_between(z,mini_QC.from_depth(qcix),mini_QC.to_depth(qcix));
            end
            bad_QC = bad_QC | this_bad_QC;
        end
        is_bad_bbp = is_bad_bbp_auto_baseline | bad_QC;
        biofloat_QC.(float_name).bad_bbp_GLOBESINK_manual = bad_QC;
    else
        is_bad_bbp = is_bad_bbp_auto_baseline;
    end
    
    biofloat_QC.(float_name).is_bad_bbp = is_bad_bbp;

    save([mat_out_folder 'f' float_name(3:end) '_QC.mat'],'biofloat_QC')
% end
    if plot_tz_sections
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
    sp(1) = subplot(4,2,1);hold on
    plot3c(t(~is_bad_bbp_auto_spikes),z(~is_bad_bbp_auto_spikes),bbp_baseline(~is_bad_bbp_auto_spikes),'.');axis ij; view(2)
    ylabel('depth (m)')
    title([float_name ' auto spike QC'])
    cbarlabel('b_b_s (m^-^1)');
    sp(2) = subplot(4,2,2);hold on
    plot3c(t(~is_bad_bbp_auto_spikes),z(~is_bad_bbp_auto_spikes),bbp_spikes(~is_bad_bbp_auto_spikes),'.');axis ij; view(2)
    title([float_name ' auto spike QC'])
    cbarlabel('b_b_l (m^-^1)');
    sp(3) = subplot(4,2,3);hold on
    plot3c(t,z,bbp_baseline,'.');axis ij; view(2)
%     plot3c(t(pass_grey),z(pass_grey),bbp_baseline(pass_grey),'.');axis ij; view(2)
    ylabel('depth (m)')
    title('raw')
    cbarlabel('b_b_s (m^-^1)');
    sp(4) = subplot(4,2,4);hold on
    plot3c(t,z,bbp_spikes,'.');axis ij; view(2)
%     plot3c(t(pass_grey),z(pass_grey),bbp_spikes(pass_grey),'.');axis ij; view(2)
    title('raw')
    cbarlabel('b_b_l (m^-^1)');
    sp(5) = subplot(4,2,5);hold on
    plot3c(t(~is_bad_bbp_auto_baseline),z(~is_bad_bbp_auto_baseline),bbp_baseline(~is_bad_bbp_auto_baseline),'.');axis ij; view(2)
    ylabel('depth (m)')
    title('auto QC');
    cbarlabel('b_b_s (m^-^1)');
    sp(6) = subplot(4,2,6);hold on
    plot3c(t(~is_bad_bbp_auto_baseline),z(~is_bad_bbp_auto_baseline),bbp_spikes(~is_bad_bbp_auto_baseline),'.');axis ij; view(2)
    title('auto QC');
    cbarlabel('b_b_l (m^-^1)');
    sp(7) = subplot(4,2,7);hold on
    plot3c(t(notbad),z(notbad),bbp_baseline(notbad),'.');axis ij; view(2)
    ylabel('depth (m)')
    title('auto and visual QC');
    cbarlabel('b_b_s (m^-^1)');
    sp(8) = subplot(4,2,8);hold on
    plot3c(t(notbad),z(notbad),bbp_spikes(notbad),'.');axis ij; view(2)
    title('auto and visual QC');
    cbarlabel('b_b_l (m^-^1)');
%
%     for fix = 1:length(float_names)
%         figure(fix)
    for vix = 1:8
        subplot(sp(vix))
        if vix >=0%3
        caxis([0 2e-3])
%         better_cmap_black_gray;
        set_cmap_red_pale_dark_bright;
        else
            caxis([0 2])
            set_cmap_green_pale_dark_bright;
        end
        ylim([0 2000])
        xlim([min(t)-1 max(t)+1])
        datetick('x','keeplimits')
    end
    clean_up_figure_text;
%     if plot_individual_maps
        set(gcf,'paperunits','inches','papersize',[20 15],'paperposition',[0 0 20 15])
%         set(gcf,'paperunits','inches','papersize',[7 2*length(ind_float_vnames)+3],'paperposition',[0 0 7  2*length(ind_float_vnames)+3])
        print('-dpng',[plot_folder float_name '_BBP700_QC.png'])
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
