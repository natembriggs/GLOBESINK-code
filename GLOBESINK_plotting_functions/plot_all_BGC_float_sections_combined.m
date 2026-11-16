function plot_all_BGC_float_sections_combined(biofloat,vnames_to_plot,BGC_Argo_plot_folder,plot_spikes,plot_lat_limits,plot_lon_limits,plot_depth_range)
% plot_all_BGC_float_sections_combined(biofloat,vnames_to_plot,BGC_Argo_plot_folder,plot_spikes,plot_lat_limits,plot_lon_limits);

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

% uvnames = fieldnames(units);
% for vix = 1:length(uvnames)
%     units.([uvnames{vix} '_ADJUSTED']) = units.(uvnames{vix});
% end
% vnames = {'DOXY'};

%             plot_individual_maps = 1;
%             plot_spikes = 1;

figure(212);clf;hold on
plot(coastlon,coastlat,'k')
%     plot(biofloat.(float_name).LONGITUDE,biofloat.(float_name).LATITUDE,'m','linewidth',3)
xlim(plot_lon_limits); ylim(plot_lat_limits)

clear h
%%


colors = [1 0 0; 0.5 0 0; 1 0.5 0; 0.9 0.9 0.1; 0.5 0.75 0; 0 0 0; 1 1 1; ...
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
%             ind_float_vnames = {'CHLA_baseline','CHLA_spikes','BBP700_baseline','BBP700_spikes'};
figure(12);clf;%hold on
for vix = 1:length(ind_float_vnames)
    sh(vix) = subplot(length(ind_float_vnames),1,vix); hold on
end

float_names = fieldnames(biofloat);
gfixs = 1:length(float_names);
for fix = 1:length(gfixs)
    float_name = float_names{gfixs(fix)};
    figure(12);%clf;hold on
    for vix = 1:length(ind_float_vnames)
%         sh(vix) = subplot(length(ind_float_vnames),1,vix); hold on
        subplot(sh(vix));
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
            end
        else
            core_vname = vname;
        end
        x = biofloat.(float_name).M_TIME;
        %                     x = biofloat.(float_name).CYCLE_NUMBER;
        y = biofloat.(float_name).PRES;
        if isfield(biofloat.(float_name),vname)
        c = biofloat.(float_name).(vname);
        if ~isempty(c)
            switch vname
                case 'DOXY'
                    c(c>400) = nan;
                    c(c<0) = nan;
                case {'CHLA','CHLA_baseline'}
                    c = c-quantile(c,0.01);
                    c(c==0) = 0.001;
            end
            c(~isnan(c)) = max(c(~isnan(c)),1e-6);
            %         c = c-min(c(:));
            g = ~isnan(c)&c>0;
            if sum(g)>10
                switch core_vname
                    case {'DOXY','NITRATE','TEMP','PSAL','PH_IN_SITU_TOTAL'}
                    otherwise
                        c = log10(c);
                end

                %         figure(10)
                %         subplot(sh(vix)); hold on
                switch core_vname
                    case {'NITRATE'}
                        hc = plot3c(x(g),y(g),-c(g),c(g),'.');axis ij;view(2)
                    otherwise
                        hc = plot3c(x(g),y(g),c(g),'.');axis ij;view(2)
                end
                set(hc,'marker','.','linewidth',2)
                if diff(quantile(c(g),[0.025 0.9975]))>0
                    caxis(quantile(c(g),[0.025 0.9975]))
                end
                datetick('x','mmm-yy')
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
            cbarlabel([vname_for_plots ' (' units.(core_vname) ')']);
            switch vname
                case 'TEMP'
%                     caxis([0 25])
                case 'DOXY'
%                     caxis([100 370])
                case 'NITRATE'
                    caxis([0 35])
                case 'PH_IN_SITU_TOTAL'
                    caxis([7.9 8.2])
                case {'CHLA','CHLA_baseline','CHLA_spikes'}
                    cbarlabel(['log_1_0 [' vname_for_plots ' (' units.(vname) ')]']);
                    caxis([-2 1.2])
                case {'BBP700','BBP700_baseline','BBP700_spikes'}
                    cbarlabel(['log_1_0 [' vname_for_plots ' (' units.(vname) ')]']);
                    caxis([-3.6 -2.0])
            end
        end
        end
        title(float_name,'color',colors(fix,:))
    end

    %     datetick('x','mmm-yy','keeplimits')

    figure(212);
    caxis([-1 1])
    if ~isempty(biofloat.(float_name).LONGITUDE)
        h(fix) = plot(biofloat.(float_name).LONGITUDE,biofloat.(float_name).LATITUDE,'linewidth',3,'color',colors(fix,:));
    end
    xlim(plot_lon_limits); ylim(plot_lat_limits)
    better_cmap_black_gray;


end
legend(h,float_names(gfixs))


% set(gcf,'paperunits','inches','papersize',[7 2*length(ind_float_vnames)],'paperposition',[0 0 7 2*length(ind_float_vnames)])
% print('-dpng',[BGC_Argo_plot_folder float_name '_' ind_float_vnames{1} '_timeseries_plot_nomap.png'])

