function bio_metadata_ix_table = get_Argo_float_type(bio_metadata_ix_table,BGC_Argo_data_folder)
% bio_metadata_ix_table = get_Argo_float_type(bio_metadata_ix_table,BGC_Argo_data_folder);
%
% For each Argo float metadata file referenced in
% "bio_metadata_ix_table", finds the corresponding metadata fields
% regarding the float make, model, and owner/operator and adds this info to
% the table
% 
% "bio_metadata_ix_table" must be created using
% function get_Argo_metadata_table.m
%
% "BGC_Argo_data_folder" must point to folder containing BGC Argo data,
% with subfolders for each DAC, each containing subfolders for each float

%% Metadata variables needed for function
vars_to_import = {'PLATFORM_TYPE','PLATFORM_MAKER','PI_NAME','FLOAT_OWNER','OPERATING_INSTITUTION','PROJECT_NAME'};%,'END_MISSION_STATUS'};

%% Loop through floats in metadata index table
for fix = 1:height(bio_metadata_ix_table)
    %%
    metafile_name = [BGC_Argo_data_folder bio_metadata_ix_table.file{fix}];
    if exist(metafile_name,'file')
        %% Load necessary metadata variables from metadata netcdf into Matlab
        for vix = 1:length(vars_to_import)
            metadata_str = ncread(metafile_name,vars_to_import{vix})';
            metadata_str = metadata_str(1:find(metadata_str~=' ',1,'last'));
            bio_metadata_ix_table.(vars_to_import{vix})(fix) = categorical({metadata_str});
        end

    else
        for vix = 1:length(vars_to_import)
            bio_metadata_ix_table.(vars_to_import{vix})(fix) = categorical({'UNKNOWN'});
        end
        disp([metafile_name ' not found'])
    end
end