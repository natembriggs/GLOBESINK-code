% GLOBESINK_combine_individual_float_mat_files.m

% if isfield(GLOBESINK_opts,'optional_variables')
%     vars_to_load = [GLOBESINK_opts.key_import_variables GLOBESINK_opts.optional_variables];
% else
%     vars_to_load = GLOBESINK_opts.key_import_variables;
% end

disp(['combining ' num2str(length(float_WMOs_to_process)) ' float files for ' GLOBESINK_opts.datafile_name]);
for fix = 1:length(float_WMOs_to_process) % 
    this_WMO = float_WMOs_to_process(fix);
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    if exist(mat_fname,'file')
        clear biofloat1
        load(mat_fname,'biofloat1')
        fnames = fieldnames(biofloat1);
        for ii = 1:length(fnames)
            fname = fnames{ii};
            biofloat.(fname) = biofloat1.(fname);
        end
        disp([num2str(fix) '/' num2str(length(float_WMOs_to_process)) ': ' mat_fname])
    else
        disp([num2str(fix) '/' num2str(length(float_WMOs_to_process)) ' NOT FOUND: ' mat_fname])
    end
end