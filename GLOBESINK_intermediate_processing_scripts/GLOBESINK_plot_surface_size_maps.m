% GLOBESINK_plot_surface_size_maps.m

load coastlines.mat
%     figure(32);clf;hold on
%%
for thismonth = 1:12
    %         subplot(3,4,thismonth)
    figure(200+thismonth);%clf;hold on
    plot(coastlon,coastlat,'k')
    cbarlabel('D mean bbp (µm)');
    caxis([0 200])
end
%%
for fix = 1:length(float_WMOs)
    this_WMO = float_WMOs(fix);
    bin_fname = [mat_file_folder 'f' num2str(this_WMO) '_pc_bins.mat'];
    if exist(bin_fname,'file')
        load(bin_fname)
        fnames = fieldnames(pc_bins1);
        fname = fnames{1};
        if isfield(pc_bins1.(fname),'nfilt')
            lbbp = length(pc_bins1.(fname).nfilt.BBP700(2,:));
            for thismonth = 1:12
                [yy, mm, dd] = datevec(pc_bins1.(fname).M_TIME(1:lbbp));
                gm = mm==thismonth&pc_bins1.(fname).nfilt.BBP700(2,:)>0;
                if sum(gm)>4
                    gmixs = find(gm);
                    %                     subplot(3,4,thismonth);hold on
                    figure(200+thismonth);hold on
                    scatter(pc_bins1.(fname).LONGITUDE(gmixs),pc_bins1.(fname).LATITUDE(gmixs),...
                        pc_bins1.(fname).nfilt.BBP700(2,gmixs),pc_bins1.(fname).D_mean_nobig.BBP700(2,gmixs),'filled')
                end
            end
        end
    end
end
