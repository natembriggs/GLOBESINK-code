function biofloat = load_BGC_Argo_data(bio_ix_table,vars_to_load,BGC_Argo_data_folder,include_adjusted_data,include_QC_flags)
% biofloat = load_BGC_Argo_data(bio_ix_table,vars_to_load,download_home,include_adjusted_data,include_QC_flags);

if nargin <5; include_QC_flags = 0; end
if nargin <4; include_adjusted_data = 0; end

if exist(BGC_Argo_data_folder,'dir')

    %% LOAD DATA
    disp('LOADING PROFILES INTO MATLAB')
%     vars_to_load = key_import_variables;
    nvars_original = length(vars_to_load);
    if include_adjusted_data
        for vix = 1:length(vars_to_load)
            vars_to_load{end+1} = [vars_to_load{vix} '_ADJUSTED'];
        end
    end
    if include_QC_flags
        for vix = 1:length(vars_to_load)
            vars_to_load{end+1} = [vars_to_load{vix} '_QC'];
        end
        for vix = 1:nvars_original
            vars_to_load{end+1} = ['PROFILE_' vars_to_load{vix} '_QC'];
        end
    end
    vars_to_load{end+1} = 'JULD'; vars_to_load{end+1} = 'LATITUDE'; vars_to_load{end+1} = 'LONGITUDE';
    vars_to_load{end+1} = 'CYCLE_NUMBER';
    clear biofloat
    load_success_count = 0;
    load_fail_count = 0;
    table_height_limit = 60000;
    if height(bio_ix_table)>table_height_limit
        disp(['truncating at ' num2str(table_height_limit) ' of ' num2str(height(bio_ix_table)) ' profiles'])
    end
    for ii = 1:min(height(bio_ix_table),table_height_limit)
        if mod(ii,100)==0
            disp([num2str(ii) '/' num2str(height(bio_ix_table))])
        end
        cd(BGC_Argo_data_folder)
        name_start_ix = find(bio_ix_table.file{ii}=='/',1,'last')+1; %find start of profile name by finding last '/' then adding 1
        float_name = bio_ix_table.file{ii}(name_start_ix:name_start_ix+8); %float name is the 8 charcters from the name_start
        %     disp(float_name)
        if ~exist('biofloat','var')||~isfield(biofloat,float_name)
            for vix = 1:length(vars_to_load)
                vname = vars_to_load{vix};
                if strcmp(vname(end-2:end),'_QC')
                    biofloat.(float_name).(vname) = '';
                else
                    biofloat.(float_name).(vname) = [];
                end
                switch vname
                    case {'BBP700','CHLA'}
                        biofloat.(float_name).([vname '_baseline'])= [];
                        biofloat.(float_name).([vname '_spikes']) = [];
                end
            end
            biofloat.(float_name).M_TIME = [];
            biofloat.(float_name).is_ascent = [];
        end

        if exist([BGC_Argo_data_folder bio_ix_table.file{ii}],'file')
            %         disp('Y')
            [l_old] = length(biofloat.(float_name).PRES);
            [m,n] = size(ncread([BGC_Argo_data_folder bio_ix_table.file{ii}],'PRES'));
            l_add = m*n;
            for vix = 1:length(vars_to_load)
%                 if vix>length(key_import_variables)||has_key_parameter_matrix(ii,vix)
                    vname = vars_to_load{vix};
                    try
                        tmp = ncread([BGC_Argo_data_folder bio_ix_table.file{ii}],vname);
                        tmp = tmp(:);
                    catch
                        tmp = nan;
                    end
                    if length(tmp)<l_add
                        tmp = tmp(1);
                    end
                    switch vname
                        case {'BBP700','BBP700_2','CHLA','BBP700_ADJUSTED','BBP700_2_ADJUSTED','CHLA_ADJUSTED'}
                            %                                     [baseline,spikes] = separate_spikes(tmp,5);
                            [baseline,spikes] = separate_spikes_median(tmp,5);
                            biofloat.(float_name).([vname '_baseline'])(l_old+(1:l_add),1) = baseline;
                            biofloat.(float_name).([vname '_spikes'])(l_old+(1:l_add),1) = spikes;
                    end
                    biofloat.(float_name).(vname)(l_old+(1:l_add),1) = tmp;
%                 end
            end
            JD = ncread([BGC_Argo_data_folder bio_ix_table.file{ii}],'JULD');
            biofloat.(float_name).M_TIME(l_old+1:l_old+l_add,1) = JD(1)+datenum(1950,1,1);
            biofloat.(float_name).is_ascent(l_old+(1:l_add),1) = bio_ix_table.file{ii}(end-3)~='D';
            load_success_count = load_success_count+1;
        else
%             disp('N')
            disp([BGC_Argo_data_folder bio_ix_table.file{ii} ' not found'])
            load_fail_count = load_fail_count+1;
        end
    end
    if ~exist('biofloat','var')
        disp('LOADING FAILED. RETURNING EMPTY STRUCT')
        disp([num2str(load_success_count) ' profiles loaded'])
        disp([num2str(load_fail_count) ' profiles not found'])
        biofloat = struct();
    else
        % REMOVE FIELDS THAT ARE ONLY NANS
        float_names = fieldnames(biofloat);
        for fix = 1:length(float_names)
            fvarnames = fieldnames(biofloat.(float_names{fix}));
            for vix = 1:length(fvarnames)
                vname = fvarnames{vix};
                if ~any(~isnan(biofloat.(float_names{fix}).(vname)))
                    biofloat.(float_names{fix}) = rmfield(biofloat.(float_names{fix}),vname);
                end
            end
        end
        disp('LOADING COMPLETE')
        disp([num2str(load_success_count) ' profiles loaded'])
        disp([num2str(load_fail_count) ' profiles not found'])
    end
end