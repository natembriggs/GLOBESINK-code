% run_GLOBESINK_auto_QC_bbp.m

QC_plot_folder = [BGC_Argo_plot_folder '/QC_plots/BGC_Argo_cdom_QC_plots/'];
for fix = 1:length(float_WMOs_to_process) % 131
    % this_WMO = 2902887;
    this_WMO = float_WMOs_to_process(fix);
    disp(num2str(fix))
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    QC_fname = [mat_file_folder  'f' num2str(this_WMO) '_cdom_QC.mat'];
    if exist(mat_fname,'file')
        if ~exist(QC_fname,'file') || GLOBESINK_opts.recalculate_cdom_QC
            load(mat_fname)
            float_names = fieldnames(biofloat1);
            if isfield(biofloat1.(float_names{1}),'CDOM')
                if exist(QC_fname,'file')
                    load(QC_fname)
                    biofloat_cdom_QC_old = biofloat_cdom_QC1; clear biofloat_cdom_QC1
                else
                    biofloat_cdom_QC_old = [];
                end
                biofloat_cdom_QC1 = GLOBESINK_cdom_data_QC(biofloat1,QC_plot_folder,...
                    plot_QC_tz_sections,biofloat_cdom_QC_old,GLOBESINK_opts.recalc_cdom_baseline);
                save(QC_fname,'biofloat_cdom_QC1')
            else
                disp([num2str(mat_fname) ' contains no cdom'])
            end
        end
    else
        disp([num2str(mat_fname) ' not found'])
    end
end