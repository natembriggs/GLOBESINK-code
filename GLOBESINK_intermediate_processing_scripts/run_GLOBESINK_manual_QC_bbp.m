% run_GLOBESINK_manual_QC_bbp.m

QC_plot_folder = [BGC_Argo_plot_folder '/QC_plots/BGC_Argo_manual_QC_plots/'];
for fix = 1:length(float_WMOs_to_process) % 131
    disp(num2str(fix))
    this_WMO = float_WMOs_to_process(fix);
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    if exist(mat_fname,'file')
        QC_fname = [mat_file_folder  'f' num2str(this_WMO) '_QC.mat'];
        if exist(QC_fname,'file')
            load(mat_fname)
            clear biofloat_QC1
            load(QC_fname)
            if ~exist('biofloat_QC1','var') % correct for old saving convention (QC, not QC1)
                biofloat_QC1 = biofloat_QC;
            end
            float_names = fieldnames(biofloat1);
            if ~isempty(float_names) && isfield(biofloat1.(float_names{1}),'BBP700')
                % biofloat_QC1 = GLOBESINK_bbp_data_QC(biofloat1,mat_file_folder,QC_plot_folder,plot_depth_sections,plot_QC_tz_sections);
                biofloat_QC1 = GLOBESINK_bbp_add_manual_QC(biofloat1,biofloat_QC1,mat_file_folder,QC_plot_folder,plot_QC_tz_sections);
                save(QC_fname,'biofloat_QC1')
            end
        end
    else
        disp([num2str(mat_fname) ' not found'])
    end
end