function [argo_data_folder,plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home)
% [argo_data_folder,plot_folder,GLOBESINK_data_folder] = get_BGC_Argo_data_and_plot_folders(download_home);

if exist(download_home,'dir')
    if ispc
        if download_home(end) ~= '\'
            download_home(end+1) = '\';
        end
    else
        if download_home(end) ~= '/'
            download_home(end+1) = '/';
        end
    end

    argo_data_folder = [download_home 'BiogeochemicalArgo/data/'];
    plot_folder = [download_home 'BiogeochemicalArgo/plots/'];
    GLOBESINK_data_folder = [download_home 'BiogeochemicalArgo/data/GLOBESINK/'];
    if ispc
        %download_home(download_home=='/') = '\';
        argo_data_folder(argo_data_folder =='/') = '\';
        plot_folder(plot_folder =='/') = '\';
    end

    if ~exist(argo_data_folder,'dir')
        mkdir(argo_data_folder)
    end
    if ~exist(plot_folder,'dir')
        mkdir(plot_folder)
    end
else
    disp(['folder not found: ' download_home])
    argo_data_folder = nan;
    plot_folder = nan;
end