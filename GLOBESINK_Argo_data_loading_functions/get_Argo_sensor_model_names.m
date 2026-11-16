function bio_metadata_ix_table = get_Argo_sensor_model_names(bio_metadata_ix_table,sensor_names_to_find,BGC_Argo_data_folder)
% bio_metadata_ix_table = get_Argo_sensor_model_names(bio_metadata_ix_table,sensor_names_to_find,BGC_Argo_data_folder);
%
% For each Argo float metadata file referenced in
% "bio_metadata_ix_table", finds the corresponding sensor model for
% each of the sensor names in cell array "sensor_names_to_find". Sensor
% models are added to "bio_metadata_is_table" with a separate data column
% for each sensor type. 
% 
% "bio_metadata_ix_table" must be created using
% function get_Argo_metadata_table.m
%
% "BGC_Argo_data_folder" must point to folder containing BGC Argo data,
% with subfolders for each DAC, each containing subfolders for each float

% sensor_names_to_find = {'OPTODE_DOXY','RADIOMETER_DOWN_IRR380','RADIOMETER_DOWN_IRR412','RADIOMETER_DOWN_IRR490','RADIOMETER_PAR','FLUOROMETER_CHLA','BACKSCATTERINGMETER_BBP700','FLUOROMETER_CDOM','TRANSISTOR_PH','SPECTROPHOTOMETER_NITRATE'};

%% Metadata variables needed for function
vars_to_import = {'SENSOR','SENSOR_MODEL','SENSOR_MAKER'};

%% Loop through floats in metadata index table
for fix = 1:height(bio_metadata_ix_table)
    %%
    metafile_name = [BGC_Argo_data_folder bio_metadata_ix_table.file{fix}];
    if exist(metafile_name,'file')
        %% Load necessary metadata variables from metadata netcdf into Matlab
        for vix = 1:length(vars_to_import)
            Argo_metadata.(vars_to_import{vix}) = ncread(metafile_name,vars_to_import{vix});
        end
        %% Get sensor and model text from metadata
        stxt = Argo_metadata.SENSOR';
        model_txt = Argo_metadata.SENSOR_MODEL';
        %% Loop through sensor names whose model names we want to interrogate
        for six = 1:length(sensor_names_to_find)
            %%
            sensor_name_to_find = sensor_names_to_find{six};
            lname = length(sensor_name_to_find);
            if size(stxt,2)>=lname
                is_gs = ismember(stxt(:,1:lname),sensor_name_to_find,'rows');
                if ~any(is_gs)
                    % if sensor name is not found, return 'NONE'
                    model_name = 'NONE';
                else
                    model_name = model_txt(is_gs,:);
                    if sum(is_gs)>1 % If sensor name is found multiple times in the metadata
                        model_name_tmp = [];
                        for ii = 1:sum(is_gs)
                            % List all sensor models separated by single spaces
                            model_name_tmp = [model_name_tmp ' ' model_name(ii,model_name(ii,:)~=' ')];
                        end
                        model_name = model_name_tmp(2:end); % remove extra space from beginning
                    else
                        model_name = model_name(model_name~=' '); % remove extra spaces from end of name
                    end
                end
            end
            % Write sensor model name to the metadata table
            bio_metadata_ix_table.([sensor_name_to_find '_MODEL'])(fix) = categorical({model_name});
        end
    else
        bio_metadata_ix_table.([sensor_name_to_find '_MODEL'])(fix) = categorical({'UNKNOWN'});
        disp([metafile_name ' not found'])
    end
end