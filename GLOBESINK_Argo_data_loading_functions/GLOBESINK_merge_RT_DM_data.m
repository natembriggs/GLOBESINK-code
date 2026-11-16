function biofloat = GLOBESINK_merge_RT_DM_data(biofloat)
% biofloat = GLOBESINK_merge_RT_DM_data(biofloat);
% 
% input: biofloat struct with separate fields for realtime (prefix SR) and delayed
% mode (prefix SD).
%
% output: biofloat struct with realtime and delayed mode data in a merged
% field (one per float; prefix SX)

float_names = fieldnames(biofloat);

%% MERGE REALTIME AND DELAYED MODE
for fix = 1:length(float_names)
    float_name = float_names{fix};
    if strcmp(float_name(1:2),'SR')
        dmname = ['SD' float_name(3:end)];
        xname = ['SX' float_name(3:end)];
        if ismember(dmname,float_names)
            if ~isempty(fieldnames(biofloat.(float_name)))&&isfield(biofloat.(float_name),'PRES')
                all_field_names = fieldnames(biofloat.(dmname));
                for vix = 1:length(all_field_names)
                    vname = all_field_names{vix};
                    if ~isfield(biofloat.(float_name),vname)
                        biofloat.(float_name).(vname) = nan(size(biofloat.(float_name).PRES));
                    end
                    biofloat.(xname).(vname) = [biofloat.(dmname).(vname); biofloat.(float_name).(vname)];
                end
                biofloat = rmfield(biofloat,dmname);
            end
            biofloat = rmfield(biofloat,float_name);
        end
    end
end