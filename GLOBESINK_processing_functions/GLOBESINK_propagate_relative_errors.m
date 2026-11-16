function monthly_maps = GLOBESINK_propagate_relative_errors(monthly_maps,input_vtype,input_vname,output_vtype,output_vname)
% monthly_maps = GLOBESINK_propagate_relative_errors(monthly_maps,input_vtype,input_vname,output_vtype,output_vname)
%
% propogates relative uncertainties from variable

if isfield(monthly_maps,'uncertainties')&&isfield(monthly_maps.uncertainties,input_vtype)&&isfield(monthly_maps.uncertainties.(input_vtype),input_vname)
    error_types = fieldnames(monthly_maps.uncertainties.(input_vtype).(input_vname)); 
    for error_type_ix = 1:length(error_types) % loop through upper and lower bound errors
        error_type = error_types{error_type_ix};
        err_names = fieldnames(monthly_maps.uncertainties.(input_vtype).(input_vname).(error_type));
        for err_ix = 1:length(err_names) % loop through error sources
            err_name = err_names{err_ix};
            v_in = monthly_maps.(input_vtype).(input_vname); v_out = monthly_maps.(output_vtype).(output_vname);
            err_in = monthly_maps.uncertainties.(input_vtype).(input_vname).(error_type).(err_name);
            monthly_maps.uncertainties.(output_vtype).(output_vname).(error_type).(err_name) =  v_out ./ v_in .* err_in;
        end
    end
else
    disp(['could not propagate errors from monthly_maps.uncertainties.' input_vtype '.' input_vname '. variable not found' ])
end
