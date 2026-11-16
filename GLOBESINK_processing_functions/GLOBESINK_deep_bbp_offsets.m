function [deep_offset_tables] = GLOBESINK_deep_bbp_offsets(monthly_bins,t_edges,zbin_edges,variable_types,variable_names,comparison_depths,float_WMOs,plot_folder,plot_offset_timeseries,max_dist,append_offsets)
% [deep_offset_tables] = GLOBESINK_deep_bbp_offsets(monthly_bins,t_edges,zbin_edges,variable_types,variable_names,comparison_depths,float_WMOs,plot_folder,plot_offset_timeseries,append_offsets);
%%
% plot_folder = [home_folder 'BiogeochemicalArgo/plots/GLOBESINK_deep_offsets/'];
% 
% variable_types = {'baseline'};
% variable_names = {'BBP700'};
% 
% 
% comparison_depths = [450 950 1700];


% disp(['input depth: ' num2str(comparison_depth) ' m; closest depth bin: ' num2str(zix) ' (' num2str(zbin_mids(zix)) ' m)'])

if nargin<11
    append_offsets = 0;
end

zbin_mids = midpoints(zbin_edges);

if plot_offset_timeseries
    load coastlines.mat
end

if ~exist(plot_folder,'dir')
    disp([plot_folder ' does not exist. making directory'])
    mkdir(plot_folder)
end
%%
lat = squeeze(monthly_bins.LATITUDE);
lon = squeeze(monthly_bins.LONGITUDE);
[ntbins,nfloats] = size(lat);
% Create table for dates
dtable = table();
t_all = t_edges(1:end-1)';
[dtable.yy,dtable.mm,dtable.dd] = datevec(t_all);
% recalc_monthly_maps = 0;
% if recalc_monthly_maps

% vtypes = fieldnames(monthly_bins);
% %%
for vtix = 1:length(variable_types)
    vtype = variable_types{vtix};
    if isfield(monthly_bins,vtype) && isstruct(monthly_bins.(vtype))
        %%
        vname = variable_names{vtix};
        deep_offsets = nan(size(float_WMOs));
        deep_offset_ns = deep_offsets;

        if append_offsets
            load([plot_folder 'GLOBESINK_float_deep_offsets_tmp.mat'])
            float_start_ix = last_saved_fix;
        else
            float_start_ix = 1;
        end

        v_all = monthly_bins.(vtype).(vname);
        % max_dist = 2000; % km
        for fix = float_start_ix:nfloats
            other_float_ixs = find(~ismember(1:nfloats,fix));
            g = any(~isnan(v_all(:,:,fix)),1);
            if any(g)
                %%
                float_t = t_all(g);float_v_mat = v_all(:,g,fix);
                float_v_reference_mat = nan(size(float_v_mat));
                float_month = dtable.mm(g);
                float_lat = lat(g,fix);
                float_lon = lon(g,fix);

                if plot_offset_timeseries
                    figure(9);clf
                    subplot(2,2,1);hold on
                    plot(float_lon,float_lat,'r','marker','.')
                    plot(coastlon,coastlat,'k');
                    xlim([-180 180]);ylim([-80 80])
                end
                for depth_ix = 1:length(comparison_depths)
                    comparison_depth = comparison_depths(depth_ix); 

                    [~,zix] = min(abs(zbin_mids-comparison_depth));

                    if plot_offset_timeseries
                        subplot(2,2,1+depth_ix);hold on
                        title(['float ' num2str(float_WMOs(fix)) '; ' num2str(zbin_mids(zix)) ' m'])
                        plot(float_t,float_v_mat(zix,:),'r','marker','.')
                        ylabel(rem_([vtype ' ' vname]))
                        datetick('x')
                    end
                end
                %%
                matchups_by_float = false(nfloats,length(float_t));
                for tix = 1:length(float_t)
                    % thist = float_t(tix);
                    thismonth = float_month(tix);
                    thislat = float_lat(tix);
                    thislon = float_lon(tix);

                    right_month = dtable.mm == thismonth;
                    rightmonth_lats = lat(right_month,:);
                    rightmonth_lons = lon(right_month,:);
                    % rightmonth_vs = v_all(:,right_month,other_float_ixs);
                    distmat = latlon_dist(thislat,thislon,rightmonth_lats,rightmonth_lons);
                    gdist = distmat<max_dist;
                    matchups_by_float(:,tix) = any(gdist,1)';
                end
                %%
                % other_float_WMOs = float_WMOs(other_float_ixs);
                % matchup_WMOs = other_float_WMOs(any(matchups_by_float,2));                
                matchup_WMOs = setdiff(float_WMOs(any(matchups_by_float,2)),float_WMOs(fix));
                float_v_reference_mat_3D = nan(size(float_v_mat,1),size(float_v_mat,2),length(matchup_WMOs));
                deep_offsets_by_float = nan(size(matchup_WMOs));
                deep_offset_ns_by_float = nan(size(matchup_WMOs));
                for f2ix = 1:length(matchup_WMOs)
                    match_float_WMO = matchup_WMOs(f2ix);
                    match_float_ix = find(float_WMOs==match_float_WMO);
                    
                    for tix = 1:length(float_t)
                        thist = float_t(tix);
                        thismonth = float_month(tix);
                        thislat = float_lat(tix);
                        thislon = float_lon(tix);

                        right_month = dtable.mm == thismonth;
                        rightmonth_lats = lat(right_month,match_float_ix);
                        rightmonth_lons = lon(right_month,match_float_ix);
                        rightmonth_vs = v_all(:,right_month,match_float_ix);
                        distmat = latlon_dist(thislat,thislon,rightmonth_lats,rightmonth_lons);
                        gdist = distmat<max_dist;
                        if any(gdist)
                            if plot_offset_timeseries
                                subplot(2,2,1)
                                gf_symbols = '.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd.*+x^vso<>_|phd';
                                hc = plot3c(rightmonth_lons(gdist),rightmonth_lats(gdist),-distmat(gdist),distmat(gdist),'.');
                                set(hc,'marker',gf_symbols(f2ix))
                            end
                            for depth_ix = 1:length(comparison_depths)
                                comparison_depth = comparison_depths(depth_ix);
                                [~,zix] = min(abs(zbin_mids-comparison_depth));
                                vs = squeeze(rightmonth_vs(zix,:,:));
                                if any(~isnan(vs(gdist)))
                                    if plot_offset_timeseries
                                        subplot(2,2,1+depth_ix);hold on
                                        hc = plot3c(thist*ones(sum(gdist(:)),1),vs(gdist),distmat(gdist),'o');
                                        set(hc,'marker',gf_symbols(f2ix))
                                        cbarlabel('dist (km)');
                                        clim([0 max_dist])
                                    end
                                    float_v_reference_mat_3D(zix,tix,f2ix) = nanmedian(vs(gdist));
                                end
                            end
                           
                        end
                    end
                    for depth_ix = 1:length(comparison_depths)
                        comparison_depth = comparison_depths(depth_ix);

                        [~,zix] = min(abs(zbin_mids-comparison_depth));

                        if plot_offset_timeseries
                            subplot(2,2,1+depth_ix);hold on
                            title(['float ' num2str(float_WMOs(fix)) '; ' num2str(zbin_mids(zix)) ' m'])
                            plot(float_t,float_v_mat(zix,:),'r','marker','.')
                            plot(float_t,float_v_reference_mat_3D(zix,:,f2ix),'marker',gf_symbols(f2ix))
                            ylabel(rem_([vtype ' ' vname]))
                            datetick('x')
                        end
                    end
                    offsets_mat = float_v_reference_mat_3D(:,:,f2ix)-float_v_mat;
                    deep_offsets_by_float(f2ix) = nanmedian(offsets_mat(:));
                    deep_offset_ns_by_float(f2ix) = sum(~isnan(offsets_mat(:)));
                end
                deep_offsets_by_float';
                deep_offset_ns_by_float';
                deep_offsets(fix) = nanmedian(deep_offsets_by_float);
                deep_offset_ns(fix) = sum(~isnan(deep_offsets_by_float));
                %%
                % for tix = 1:length(float_t)
                %     thist = float_t(tix);
                %     thismonth = float_month(tix);
                %     thislat = float_lat(tix);
                %     thislon = float_lon(tix);
                % 
                %     right_month = dtable.mm == thismonth;
                %     rightmonth_lats = lat(right_month,other_float_ixs);
                %     rightmonth_lons = lon(right_month,other_float_ixs);
                %     rightmonth_vs = v_all(:,right_month,other_float_ixs);
                %     distmat = latlon_dist(thislat,thislon,rightmonth_lats,rightmonth_lons);
                %     gdist = distmat<max_dist;
                %     gfs = any(gdist,1);
                %     gfixs = find(gfs);
                %     if plot_offset_timeseries
                %         subplot(2,2,1)
                %         plot3c(rightmonth_lons(gdist),rightmonth_lats(gdist),-distmat(gdist),distmat(gdist),'.');
                %         % gf_symbols = '*+x^vso*+x^vso*+x^vso*+x^vso*+x^vso';
                %         % %%
                %         % gcount = 0; clear hc; plotted_fixs = [];
                %         % for gfix_ix = 1:length(gfixs)
                %         %     gfix = gfixs(gfix_ix);
                %         %     gdist1 = false(size(gdist));
                %         %     gdist1(:,gfix) = gdist(:,gfix);
                %         %     if any(gdist1(:))
                %         %         gcount = gcount+1;
                %         %         hc(gcount) = plot3c(rightmonth_lons(gdist1),rightmonth_lats(gdist1),-distmat(gdist1),distmat(gdist1),'.');
                %         %         set(hc(gcount),'marker',gf_symbols(gfix_ix))
                %         %         plotted_fixs = [plotted_fixs; gfix];
                %         %     end
                %         % end
                %         % %%
                %         % legend(hc,num2str(float_WMOs(plotted_fixs)))
                % 
                %     end
                %     %%
                %     for depth_ix = 1:length(comparison_depths)
                %         comparison_depth = comparison_depths(depth_ix);
                %         [~,zix] = min(abs(zbin_mids-comparison_depth));
                %         vs = squeeze(rightmonth_vs(zix,:,:));
                %         if any(~isnan(vs(gdist)))
                %             if plot_offset_timeseries
                %                 subplot(2,2,1+depth_ix);hold on
                %                 plot3c(thist*ones(sum(gdist(:)),1),vs(gdist),distmat(gdist),'o');
                %                 cbarlabel('dist (km)');
                %                 clim([0 max_dist])
                %             end
                %             float_v_reference_mat(zix,tix) = nanmedian(vs(gdist));
                %         end
                %     end
                % 
                % 
                % end
                % for depth_ix = 1:length(comparison_depths)
                %     comparison_depth = comparison_depths(depth_ix);
                % 
                %     [~,zix] = min(abs(zbin_mids-comparison_depth));
                % 
                %     if plot_offset_timeseries
                %         subplot(2,2,1+depth_ix);hold on
                %         title(['float ' num2str(float_WMOs(fix)) '; ' num2str(zbin_mids(zix)) ' m'])
                %         plot(float_t,float_v_mat(zix,:),'r','marker','.')
                %         plot(float_t,float_v_reference_mat(zix,:),'m','marker','.')
                %         ylabel(rem_([vtype ' ' vname]))
                %         datetick('x')
                %     end
                % end
                % deep_offsets(fix) = nanmedian(float_v_reference_mat(:)-float_v_mat(:));
                % deep_offset_ns(fix) = sum(~isnan(float_v_reference_mat(:)-float_v_mat(:)));
                if plot_offset_timeseries
                    subplot(2,2,1);
                    title(['median offset: ' num2str(deep_offsets(fix))])
                    set(gcf,'paperunits','inches','papersize',[16 10],'paperposition',[0 0 16 10])
                    print('-dpng',[plot_folder [vname '_' vtype '_offsets_' num2str(float_WMOs(fix))] '.png'])
                end
            end
            if mod(fix,10)==0
                last_saved_fix = fix;
                save([plot_folder 'GLOBESINK_float_deep_offsets_tmp.mat'],'deep_offsets','deep_offset_ns','last_saved_fix');
                disp(['float ' num2str(fix) '/' num2str(length(float_WMOs))])
            end
        end
        %%
        deep_offset_tables.(vtype).(vname) = table(float_WMOs,deep_offsets,deep_offset_ns);
    end
end
end
