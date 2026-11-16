% GLOBESINK_save_individual_float_mat_files.m

if isfield(GLOBESINK_opts,'optional_variables')
    vars_to_load = [GLOBESINK_opts.key_import_variables GLOBESINK_opts.optional_variables];
else
    vars_to_load = GLOBESINK_opts.key_import_variables;
end

restart_saving_where_left_off = 0;
if exist('last_float_ix_saved','var') && restart_saving_where_left_off
    fstartix = last_float_ix_saved+1;
else
    fstartix = 1;
end
% fstartix = 41;

for fix = fstartix:length(float_WMOs_to_process) % 284
    this_WMO = float_WMOs_to_process(fix);
    mat_fname = [mat_file_folder 'f' num2str(this_WMO) '.mat'];
    if (isfield(GLOBESINK_opts,'resave_individual_float_mat_files') && GLOBESINK_opts.resave_individual_float_mat_files) ...
            || ~exist(mat_fname,'file')
        clear biofloat1
        if exist('biofloat','var')
            if isfield(biofloat,['SR' num2str(this_WMO)])
                biofloat1.(['SR' num2str(this_WMO)]) = biofloat.(['SR' num2str(this_WMO)]);
            elseif isfield(biofloat,['SD' num2str(this_WMO)])
                biofloat1.(['SD' num2str(this_WMO)]) = biofloat.(['SD' num2str(this_WMO)]);
            elseif isfield(biofloat,['SX' num2str(this_WMO)])
                biofloat1.(['SX' num2str(this_WMO)]) = biofloat.(['SX' num2str(this_WMO)]);
            end
        end
        if ~exist('biofloat1','var')
            is_this_float = bio_ix_table_by_float.float == this_WMO;
            disp(['loading float ' num2str(this_WMO)])
            biofloat1 = load_BGC_Argo_data(bio_ix_table_by_float(is_this_float,:),vars_to_load,BGC_Argo_data_folder,GLOBESINK_opts.include_adjusted_data,GLOBESINK_opts.include_QC_flags);
            biofloat1 = GLOBESINK_merge_RT_DM_data(biofloat1);
        end
        if ~exist(mat_file_folder,'dir')
            mkdir(mat_file_folder)
        end
        if length(fieldnames(biofloat1))>0
            save(mat_fname,'biofloat1')
            disp(num2str(fix))
        end
        last_float_ix_saved = fix;
    end
end