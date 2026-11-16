function monthly_maps = GLOBESINK_combine_precisions(monthly_maps,vtype,vname)
% monthly_maps = GLOBESINK_combine_precisions(monthly_maps,vtype,vname);
%
% quadratically combines precisions from multiple sources

if isfield(monthly_maps,'uncertainties') && isfield(monthly_maps.uncertainties,vtype)&&isfield(monthly_maps.uncertainties.(vtype),vname)
    error_types = fieldnames(monthly_maps.uncertainties.(vtype).(vname)); 
    for error_type_ix = 1:length(error_types) % loop through upper and lower bound errors
        error_type = error_types{error_type_ix};
        total_error = 0;
        err_names = fieldnames(monthly_maps.uncertainties.(vtype).(vname).(error_type));
        for err_ix = 1:length(err_names) % loop through error sources
            err_name = err_names{err_ix};
            if length(err_name)>9&&strcmp(err_name(1:9),'precision')
                total_error = sqrt(total_error.^2 + monthly_maps.uncertainties.(vtype).(vname).(error_type).(err_name).^2);
            end
        end
        monthly_maps.uncertainties.(vtype).(vname).(error_type).precision = total_error;
    end
else
    disp(['could not generate errors from monthly_maps.uncertainties' vtype '.' vname ' – variable not found' ])
end
