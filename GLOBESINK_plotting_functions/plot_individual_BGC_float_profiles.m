function plot_individual_BGC_float_profiles(biofloat,vnames_to_plot,profile_plot_folder,plot_individual_maps,plot_spikes,plot_lat_limits,plot_lon_limits,plot_depth_range)
% plot_individual_BGC_float_profiles(biofloat,vnames_to_plot,profile_plot_folder,plot_individual_maps,plot_spikes,plot_lat_limits,plot_lon_limits);
%%
% profile_plot_folder = [BGC_Argo_plot_folder 'profile_plots/'];
if ~exist(profile_plot_folder,'dir')
    mkdir(profile_plot_folder);
end

load coastlines.mat
%% plot individual floats
% vnames = {'CHLA','BBP700'};
units.TEMP = '°C';
units.PSAL = 'psu';
units.CHLA = 'mg m^-^3';
units.BBP700 = 'm^-^1';
units.CHLA_baseline = 'mg m^-^3';
units.BBP700_baseline = 'm^-^1';
units.CHLA_spikes = 'mg m^-^3';
units.BBP700_spikes = 'm^-^1';
units.DOXY = 'µmol kg^-^1';
units.NITRATE = 'µmol L^-^1';
units.DOWNWELLING_PAR = 'µmol m^-^2 s^-^1';
units.PH_IN_SITU_TOTAL = '';
units.CDOM = 'ppb';

% uvnames = fieldnames(units);
% for vix = 1:length(uvnames)
%     units.([uvnames{vix} '_ADJUSTED']) = units.(uvnames{vix});
% end
% vnames = {'DOXY'};

%             plot_individual_maps = 1;
%             plot_spikes = 1;
combined_vnames = vnames_to_plot{1};
for vix = 2:length(vnames_to_plot)
    combined_vnames = [combined_vnames '_' vnames_to_plot{vix}];
end

if ~plot_individual_maps
    figure(212);clf;hold on
    plot(coastlon,coastlat,'k')
    %     plot(biofloat.(float_name).LONGITUDE,biofloat.(float_name).LATITUDE,'m','linewidth',3)
    xlim(plot_lon_limits); ylim(plot_lat_limits)
end

clear h
%%


colors = [1 0 0; 0.5 0 0; 1 0.5 0; 0.9 0.9 0.1; 0.5 0.75 0; 0 0 0; ...
    0 1 0; 0.5 0.5 0.5; 0.9 0.1 0.9; 1 1 0; 1 0 1; 0 1 1; 0.75 0.75 0.75; ...
    0.5 0.5 0; 0 0.5 0.5; 0.5 0 0.5; 0.3 0.3 0.3; 0.3 0 0; 0 0.3 0; 0 0 0.3; ...
    0.3 0.3 0; 0.3 0 0.3; 0 0.3 0.3; 0.7 0 0; 0 0.7 0; 0 0 0.7; ...
    0.7 0.7 0; 0 0.7 0.7; 0.7 0 0.7; 0.7 0.4 0.4; 0.4 0.7 0.4; 0.4 0.4 0.7; 0.7 0.7 0.4; 0.7 0.4 0.7; 0.4 0.7 0.7];
colors = [colors; colors; colors];

ind_float_vnames = vnames_to_plot;
if plot_spikes
    for vix = 1:length(ind_float_vnames)
        switch ind_float_vnames{vix}
            case {'CHLA','BBP700'}
                ind_float_vnames{end+1} = [ind_float_vnames{vix} '_spikes'];
        end
    end
end
nvs = length(ind_float_vnames)+plot_individual_maps;
msubplot = floor(sqrt(nvs));
nsubplot = ceil(nvs/msubplot);
%             ind_float_vnames = {'CHLA_baseline','CHLA_spikes','BBP700_baseline','BBP700_spikes'};
float_names = fieldnames(biofloat);
gfixs = 1:length(float_names);
for fix = 1:length(gfixs)
    float_name = float_names{gfixs(fix)};
    figure(11);clf;hold on
    for vix = 1:length(ind_float_vnames)
%         if plot_individual_maps
            sh(vix) = subplot(msubplot,nsubplot,vix); hold on
%         else
%             sh(vix) = subplot(length(ind_float_vnames),1,vix); hold on
%         end
        vname = ind_float_vnames{vix};
        switch vname
            case {'CHLA','BBP700'}
                vname = [vname '_baseline'];
        end
        vname_underscore_ixs = find(vname=='_');
        vname_for_plots = vname; 
        if any(vname=='_') 
            vname_for_plots(vname_underscore_ixs) = ' ';
            if ~strcmp(vname(1:4),'DOWN') && ~strcmp(vname(1:4),'PH_I')
                core_vname = vname(1:find(vname=='_',1,'first')-1);
            else
                core_vname = vname;
            end
        else
            core_vname = vname;
        end
        x = biofloat.(float_name).M_TIME;
        %                     x = biofloat.(float_name).CYCLE_NUMBER;
        y = biofloat.(float_name).PRES;
        c = biofloat.(float_name).(vname);
        if ~isempty(c)
%             switch vname
%                 case 'DOXY'
%                     c(c>400) = nan;
%                     c(c<0) = nan;
%                 case {'CHLA','CHLA_baseline'}
%                     c = c-quantile(c,0.01);
%                     c(c==0) = 0.001;
%             end
%             c(~isnan(c)) = max(c(~isnan(c)),1e-6);
            %         c = c-min(c(:));
            g = ~isnan(c)&y>1;%&c>0;
            if sum(g)>10
                switch core_vname
                    case {'DOXY','NITRATE','TEMP','PSAL','PH_IN_SITU_TOTAL'}
                    otherwise
%                         c = log10(c);
                end

                %         figure(10)
                %         subplot(sh(vix)); hold on
%                 switch core_vname
%                     case {'NITRATE'}
%                         hc = plot3c(x(g),y(g),-c(g),c(g),'.');axis ij;view(2)
%                     otherwise
                        hc = plot3c(c(g),y(g),x(g),'.');axis ij;view(2)
%                 end
                set(hc,'marker','.','linewidth',2)
                if diff(quantile(c(g),[0.025 0.9975]))>0
%                     xlim(quantile(c(g),[0.025 0.9975]))
                end
%                 datetick('x','mmm-yy')
                %         cbarlabel(['log_1_0 ' vname]);
                better_cmap_black_gray;
            end
            %         figure(110)
            %         subplot(sh110(vix)); hold on
            %         plot3c(c(g),y(g),x(g),'o');axis ij;view(2)
            % %         caxis(quantile(c(g),[0.025 0.995]))
            % %         datetick('x','mmm-yy')
            %         better_cmap_black_gray;

            %         xlim(time_limits)
            ylim(plot_depth_range)
            %         datetick('x','mmm-yy','keeplimits')
            %         datetick('x','yyyy','keeplimits')
            
            xlabel([vname_for_plots ' (' units.(core_vname) ')']);
            switch vname
                case 'DOWNWELLING_PAR'
                    ylim([0 300])
            end
%             switch vname
%                 case 'TEMP'
% %                     caxis([0 25])
%                 case 'DOXY'
% %                     caxis([100 370])
%                 case 'NITRATE'
%                     xlim([0 35])
%                 case 'PH_IN_SITU_TOTAL'
%                     xlim([7.9 8.2])
%                 case {'CHLA','CHLA_baseline','CHLA_spikes'}
%                     xlabel(['log_1_0 [' vname_for_plots ' (' units.(vname) ')]']);
%                     xlim([-2 1.2])
%                 case {'BBP700','BBP700_baseline','BBP700_spikes'}
%                     xlabel(['log_1_0 [' vname_for_plots ' (' units.(vname) ')]']);
%                     xlim([-3.6 -2.0])
%             end
        end
        title(float_name,'color',colors(fix,:))
    end
    ch = cbarlabel('');
    datetick(ch,'y')
    if ~plot_individual_maps
        set(gcf,'paperunits','inches','papersize',[14 10],'paperposition',[0 0 14 10])
        print('-dpng',[profile_plot_folder float_name '_' combined_vnames '_profiles_plot_nomap.png'])
    end

    if plot_individual_maps
        subplot(msubplot,nsubplot,length(ind_float_vnames)+1);hold on
        %         pcolor(xsat,ysat,log10(csat));shading flat
        plot(coastlon,coastlat,'k')
        caxis([-1 1])
        if ~isempty(biofloat.(float_name).LONGITUDE)
            h(fix) = plot(biofloat.(float_name).LONGITUDE,biofloat.(float_name).LATITUDE,'linewidth',3,'marker','*','color',colors(fix,:));
        end
        xlim(plot_lon_limits); ylim(plot_lat_limits)
        better_cmap_black_gray;
%         plot(-89.13,[-54.415 -57 -59.96],'m','marker','o','linewidth',2)
%     else
%         figure(212);
    end

    if plot_individual_maps
        set(gcf,'paperunits','inches','papersize',[14 10],'paperposition',[0 0 14 10])
        print('-dpng',[profile_plot_folder float_name '_' combined_vnames '_profiles_plot_w_map.png'])
    end

end

if ~plot_individual_maps
    figure(212);%clf;hold on
    for fix = 1:length(gfixs)
        float_name = float_names{gfixs(fix)};
        caxis([-1 1])
        if ~isempty(biofloat.(float_name).LONGITUDE)
            h(fix) = plot(biofloat.(float_name).LONGITUDE,biofloat.(float_name).LATITUDE,'linewidth',3,'marker','*','color',colors(fix,:));
        end

    end
    xlim(plot_lon_limits); ylim(plot_lat_limits)
    better_cmap_black_gray;

    legend(h,float_names(gfixs))
end