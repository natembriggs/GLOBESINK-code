% GLOBESINK_plot_percast_bins.m

pc_plot_folder = [BGC_Argo_plot_folder '/binned_data/'];
disp('plotting percast bins')
vnames = {'BBP700','BBP700','BBP700','BBP700','BBP700'};
vtypes = {'baseline2','spikes_noise2','spikes2','spikes_big2','nfilt'};
for fix = 1:length(float_WMOs_to_process) % 173 804
    this_WMO = float_WMOs_to_process(fix);
    %             disp(this_WMO)
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    bin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins' QC_text '.mat'];
    if exist(bin_fname,'file')
    load(bin_fname);
    load(mat_fname);
    fnames = fieldnames(pc_bins1); fname = fnames{1};
    x = pc_bins1.(fname).M_TIME;
    y = pc_bins1.(fname).PRES;
    figure(41);clf;hold on
    for vix = 1:length(vtypes)
        vname = vnames{vix};
        vtype = vtypes{vix};
        c = pc_bins1.(fname).(vtype).(vname);
        % if strcmp(vname,'BBP700')
        %     c = c*35000;
        %     if ismember(vtype,{'spikes','spikes_noise','spikes_big'})
        %         c = c*75;
        %     end
        % end
        subplot(3,3,vix);
        pcolor(x,y,c);shading flat; axis ij
        ylim([0 1000])
        switch vtype
            case {'baseline','baseline2'}
                clim([0 0.01])
            case {'spikes','spikes_big','spikes2','spikes_big2'}
                clim([0 0.01]/20)
        end
        datetick('x');
        cbarlabel(rem_([vname ' ' vtype]));
        better_cmap_black_gray;
    end
    subplot(3,3,6);hold on
    c = pc_bins1.(fname).spikes_big.BBP700./pc_bins1.(fname).spikes.BBP700;
    pcolor(x,y,c);shading flat; axis ij
    ylim([0 1000])
    datetick('x');
    cbarlabel('big spikes / spikes');
    clim([0 10]);
    better_cmap_black_gray;

    % plot3c(pc_bins1.(fname).spikes.BBP700,...
    %     pc_bins1.(fname).spikes_big.BBP700,...
    %     pc_bins1.(fname).baseline.BBP700,'.');
    % plot3c(pc_bins1.(fname).spikes.BBP700*35000*75,...
    %     pc_bins1.(fname).spikes_big.BBP700*35000*75,...
    %     pc_bins1.(fname).baseline.BBP700*35000,'.');
    % xlabel('spikes');ylabel('big spikes');cbarlabel('baseline');
    rvars = {'BBP700_baseline','BBP700_spikes','CHLA_baseline'};
    for vix = 1:length(rvars)
        subplot(3,3,6+vix);hold on
        plot3c(biofloat1.(fname).M_TIME,biofloat1.(fname).PRES,biofloat1.(fname).(rvars{vix}),'.');
        view(2);axis ij
        better_cmap_black_gray;
        datetick('x');
        cbarlabel(rem_(rvars{vix}));
        if vix==3
            clim([0 15])
        else
            clim([0 0.01])
        end
    end
    set(gcf,'paperunits','inches','papersize',[20 10],'paperposition',[0 0 20 10])
    %         set(gcf,'paperunits','inches','papersize',[7 2*length(ind_float_vnames)+3],'paperposition',[0 0 7  2*length(ind_float_vnames)+3])
    print('-dpng',[pc_plot_folder fname '_BBP700_pc_bins.png'])
    end
end
