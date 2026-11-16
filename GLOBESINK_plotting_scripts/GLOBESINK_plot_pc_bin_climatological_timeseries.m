% GLOBESINK_plot_pc_bin_climatological_timeseries.m
clear
%% Set data and plot folders
download_home = home_folder;
[BGC_Argo_data_folder,BGC_Argo_plot_folder] = get_BGC_Argo_data_and_plot_folders(download_home);
mat_file_folder = [download_home 'BiogeochemicalArgo/single_float_data_mat_format/'];

GLOBESINK_opts.datafile_name = 'ICB';
load(['float_WMOs_' GLOBESINK_opts.datafile_name '.mat'])
load([BGC_Argo_data_folder 'BGC_Argo_data_' GLOBESINK_opts.datafile_name '_metadata.mat'])

load('BGC_Argo_data_UVP_validation_aux.mat')
UVP_fnames = {'WMO1902637','WMO4903659','WMO6904240'};%,'WMO6990636'};
% UVP_fnames = {'SR4903659','SR6990636','SR1902637','SR6904240'};%};

% load coastlines.mat
%     figure(32);clf;hold on
%%
% for thismonth = 1:12
%         subplot(3,4,thismonth)
figure(200);clf;hold on
% plot(coastlon,coastlat,'k')
% cbarlabel('D mean bbp (µm)');
% caxis([0 200])
% end
%
types_to_plot = {'baseline','D_mean_nobig','baseline','spikes','spikes','baseline',...
    'spikes','spikes','baseline','spikes','spikes','baseline'};
vars_to_plot = {'CHLA','BBP700','BBP700','CHLA','BBP700','BBP700',...
    'CHLA','BBP700','BBP700','CHLA','BBP700','BBP700'};
zbins_to_plot = [2 2 2 6 6 6 10 10 10 14 14 14];
for vix = 1:length(types_to_plot)
    subplot(4,3,vix);hold on
    vtype = types_to_plot{vix};
    vname = vars_to_plot{vix};
    zbin = zbins_to_plot(vix);
    x_all = []; y_all = [];
    for fix = 1:length(float_WMOs)
        this_WMO = float_WMOs(fix);
        bin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins.mat'];
        if exist(bin_fname,'file')
            load(bin_fname)
            zbin_text = [num2str(bin_opts1.zbin_edges(zbin)) '-' num2str(bin_opts1.zbin_edges(zbin+1))];
            fnames = fieldnames(pc_bins1);
            fname = fnames{1};
            if isfield(pc_bins1.(fname),'nfilt')
                % lbbp = length(pc_bins1.(fname).nfilt.BBP700(2,:));
                % for thismonth = 1:12
                glatlon = is_between(pc_bins1.(fname).LONGITUDE,GLOBESINK_opts.import_lon_limits) & ...
                    is_between(pc_bins1.(fname).LATITUDE,GLOBESINK_opts.import_lat_limits)&...
                    (pc_bins1.(fname).nfilt.(vname)(zbin,:))>0&~isnan(pc_bins1.(fname).(vtype).(vname)(zbin,:));
                [yy, mm, dd] = datevec(pc_bins1.(fname).M_TIME);
                if any(glatlon)
                    doy = datenum(0,mm,dd);
                    thisyear = yy==2024&glatlon;
                    nextyear = yy==2025&glatlon;
                    % gm = mm==thismonth&pc_bins1.(fname).nfilt.(vname)(zbin,:)>0;
                    % if sum(gm)>4
                    % gmixs = find(gm);
                    %                     subplot(3,4,thismonth);hold on
                    h = scatter(doy(glatlon),pc_bins1.(fname).(vtype).(vname)(zbin,glatlon),...
                        pc_bins1.(fname).nfilt.(vname)(zbin,glatlon));
                    set(h,'markeredgecolor',[0.7 0.7 0.7])
                    if any(thisyear)
                        thisx = doy(thisyear); thisy = pc_bins1.(fname).(vtype).(vname)(zbin,thisyear);
                        h = scatter3(thisx,thisy,...
                            ones(size(doy(thisyear))),pc_bins1.(fname).nfilt.(vname)(zbin,thisyear),'filled');
                        set(h,'markerfacecolor',[1 0 0])
                        x_all = [x_all thisx];
                        y_all = [y_all thisy];

                    end
                    if any(nextyear)
                        h = scatter3(doy(nextyear),pc_bins1.(fname).(vtype).(vname)(zbin,nextyear),...
                            ones(size(doy(nextyear))),pc_bins1.(fname).nfilt.(vname)(zbin,nextyear),'filled');
                        set(h,'markerfacecolor',[0 0.7 0])

                    end
                    % end
                    % end
                end
                % disp([fname ': ' num2str(sum(glatlon))])
            end
        end
    end
    [x_all,sort_ix] = sort(x_all);
    y_all = y_all(sort_ix);
    % yfit = running_polyfit2(x_all,y_all,20,20,2,1);
    yfit = running_quantile_fit(x_all,y_all,20,20,2,0.5);
    plot3(x_all,yfit,ones(size(x_all))*2.2,'k');
    xs.(vtype).(vname).(['z' num2str(zbin)]) = x_all;
    ys.(vtype).(vname).(['z' num2str(zbin)]) = yfit;
    ylabel([vname ' ' rem_(vtype) ' ' zbin_text ' m'])
    xlim([0 365])
    datetick('x','mmm','keeplimits')
    if strcmp(vtype,'spikes') && strcmp(vname,'BBP700')
        subplot(4,3,vix+1);hold on
        [x_smooth,y2_smooth] = binaverage_edges(x_all,yfit',0:10:365);
        y2_pred = zeros(size(y2_smooth));
        y2_smooth(isnan(y2_smooth))=0;
        z_range = bin_opts1.zbin_edges(zbin+(0:1));
        % F_l = (0.27*exp(-0.24*midpoints(z_range)/100))+0.02; % fragmentation rate
        % m_bbp = 0.02+0.1*exp(-0.8*midpoints(z_range)/100);
        % F_l = 0.18; % fragmentation rate
        F_l = 0.51./(midpoints(z_range))*75;
            if midpoints(z_range)>600
                F_l = 0.094;
            else
                F_l = 0.12;
            end
        m_bbp = 0.032;
        for ii = 2:length(y2_pred)
            y2_pred(ii) = y2_pred(ii-1)*(1-m_bbp)^10+y2_smooth(ii-1)*F_l*10;
        end
        y2_pred(1) = y2_pred(end);
        for ii = 2:length(y2_pred)
            y2_pred(ii) = y2_pred(ii-1)*(1-m_bbp)^10+y2_smooth(ii-1)*F_l*10;
        end
        
        y2_smooth = y2_pred+2e-4;
        % plot3(x_smooth,y2_smooth,ones(size(y2_smooth))*2,'color',[0.5 0 0.5],'linewidth',2);
        
    end
end
subplot(4,3,4);ylim([0 0.15])
subplot(4,3,7);ylim([0 0.15])
subplot(4,3,10);ylim([0 0.15])
subplot(4,3,5);ylim([0 2.5e-4])
subplot(4,3,8);ylim([0 2.5e-4])
subplot(4,3,11);ylim([0 2.5e-4])
for ii = 1:12
    subplot(4,3,ii);hold on
    y_limits = get(gca,'ylim');
    y_limits(1)=0;
    % plot(datenum(0,7,1)*[1 1],y_limits,'k')
    plot(datenum(0,6,23)*[1 1],y_limits,'k')
    plot(datenum(0,5,28)*[1 1],y_limits,'k')
    ylim(y_limits)
end
%
if exist('hs2','var')
    try delete(hs2)
    catch
        disp('no data in hs2')
    end
end
% figure(1);clf;
UVP_sp_ixs = [2 5 6 8 9 11 12];
% UVP_sp_ixs = [5 6 8 9 11 12];
color_fades = [0 0 0.8 0.9];
for fix = 1:3%length(UVP_fnames)
    fname = UVP_fnames{fix};
    
    color_fade = color_fades(fix);
    for zix = 1:length(UVP_sp_ixs)
        sp_ix = UVP_sp_ixs(zix);
        zbin_ix = zbins_to_plot(sp_ix);
        z_range = bin_opts1.zbin_edges(zbin_ix+(0:1));
        t = biofloat_aux.(fname).M_TIME;
        [yyyy,~,~] = datevec(t);
        gz = is_between(biofloat_aux.(fname).PRES,z_range)&yyyy>=2024;
        subplot(4,3,sp_ix);hold on
        x = t-datenum(yyyy,1,1);
        y = biofloat_aux.(fname).uvp_bb;
        y2 = biofloat_aux.(fname).uvp_bb_2;
        if sp_ix == 2
            y2 = y2*1e5;
        end
        [x_smooth,y_smooth] = binaverage_edges(x(gz),y(gz),0:10:365);
        [~,y2_smooth] = binaverage_edges(x(gz),y2(gz),0:10:365);
        if mod(sp_ix,3)==0 && sp_ix>3
            y_pred = zeros(size(y_smooth));
            y2_pred = zeros(size(y2_smooth));
            y2_smooth(isnan(y2_smooth))=0;
            y_smooth(isnan(y_smooth))=0;
            % F_l = (0.27*exp(-0.24*midpoints(z_range)/100))+0.02; % fragmentation rate
            % F_l = (0.14*exp(-0.24*midpoints(z_range)/100))+0.04; % fragmentation rate
            % m_bbp = 0.02+0.1*exp(-0.8*midpoints(z_range)/100);
            % F_l = 0.51./(midpoints(z_range))*75;
            F_l = 0.78./(midpoints(z_range))*75;
            m_bbp = 0.032; 
            if midpoints(z_range)>600
                F_l = 0.094;
                m_bbp = 0.032; 
            elseif midpoints(z_range)>400
                F_l = 0.11;
            else
                F_l = 0.13;
                % m_bbp = 0.029; 
            end
            % F_l = 0.18; %;0.18; % fragmentation rate
            % m_bbp = 0.02;%+0.27*exp(-1.4*midpoints(z_range)/100);
            % title(['z: ' num2str(midpoints(z_range)) '; F:' num2str(F_l,2) '; m:' num2str(m_bbp,2)])
            title(['F:' num2str(F_l,2) ' (d^-^1);    m:' num2str(m_bbp,2) ' (d^-^1)'])
            for ii = 2:length(y2_pred)
                y2_pred(ii) = y2_pred(ii-1)*(1-m_bbp)^10+y2_smooth(ii-1)*F_l*10;
                y_pred(ii) = y_pred(ii-1)*(1-m_bbp)^10+y_smooth(ii-1)*F_l*10;
            end
            y2_pred(1) = y2_pred(end);
            y_pred(1) = y_pred(end);
            for ii = 2:length(y2_pred)
                y2_pred(ii) = y2_pred(ii-1)*(1-m_bbp)^10+y2_smooth(ii-1)*F_l*10;
                y_pred(ii) = y_pred(ii-1)*(1-m_bbp)^10+y_smooth(ii-1)*F_l*10;
            end
            y2_smooth = y2_pred+2e-4;
            y_smooth = y_pred+2e-4;
        end
        % x_smooth = x(gz);
        % y_smooth = running_mean(y(gz),5);
        % y2_smooth = running_mean(y2(gz),5);
        % x_smooth = x_smooth(2:5:end); y_smooth = y_smooth(2:5:end); y2_smooth = y2_smooth(2:5:end); 
        % hs1(fix,zix) = plot3(x_smooth,y_smooth,ones(size(y_smooth))*2,'c','linewidth',2);
        if mod(sp_ix,3)==0 && sp_ix>3
        else
        hs2(fix,zix) = plot3(x_smooth,y2_smooth,ones(size(y_smooth))*2,'color',[0 color_fade 1],'linewidth',2);
        end
        plot3(x_smooth,y_smooth,ones(size(y_smooth))*2,'color',[0.5 color_fade 0.5],'linewidth',2);
    end
end
%%
% Prints current figure to pdf on Desktop

set(gcf,'paperunits','inches','papersize',[15 10],'paperposition',[0 0 15 10])
print('-dpng',['~/Desktop/BIO_Carbon_float_spike_TS.png'])
% end