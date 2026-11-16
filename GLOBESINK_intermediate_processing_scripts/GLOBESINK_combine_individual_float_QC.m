% GLOBESINK_combine_individual_float_QC.m

for fix = 1:length(float_WMOs_to_process) % 131
    disp(num2str(fix))
    this_WMO = float_WMOs_to_process(fix);
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    if exist(mat_fname,'file')
        QC_fname = [mat_file_folder  'f' num2str(this_WMO) '_QC.mat'];
        if exist(QC_fname,'file')
            load(QC_fname)
            float_names = fieldnames(biofloat_QC1);
            for ii = 1:length(float_names)
                fname = float_names{ii};
                biofloat_QC.(fname) = biofloat_QC1.(fname);
            end
        else
            disp([num2str(QC_fname) ' not found'])
        end
    else
        disp([num2str(mat_fname) ' not found'])
    end
end