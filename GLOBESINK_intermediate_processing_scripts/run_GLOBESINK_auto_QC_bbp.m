% run_GLOBESINK_manual_QC_bbp.m

QC_plot_folder = [BGC_Argo_plot_folder '/QC_plots/BGC_Argo_bbp_QC_plots/'];
for fix = 1:length(float_WMOs_to_process) % 131
    % this_WMO = 2902887;
    this_WMO = float_WMOs_to_process(fix);
    disp(num2str(fix))
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    QC_fname = [mat_file_folder  'f' num2str(this_WMO) '_QC.mat'];
    if exist(mat_fname,'file')
        if ~exist(QC_fname,'file') || GLOBESINK_opts.recalculate_bbp_QC
            load(mat_fname)
            float_names = fieldnames(biofloat1);
            if ~isempty(float_names) && isfield(biofloat1.(float_names{1}),'BBP700')
                biofloat_QC1 = GLOBESINK_bbp_data_QC(biofloat1,QC_plot_folder,plot_QC_depth_sections,plot_QC_tz_sections);
                save(QC_fname,'biofloat_QC1')
            end
        end
    else
        disp([num2str(mat_fname) ' not found'])
    end
end