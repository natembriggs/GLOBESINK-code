function monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,input_vtype,input_vname,output_vtype,output_vname,m,b,output_error_suffix,error_names)
% monthly_maps = GLOBESINK_propagate_errors_linear(monthly_maps,input_vtype,input_vname,output_vtype,output_vname,m,b,output_error_suffix,error_names);
%%
if nargin<7
    b = 0;
end
if nargin<8
    output_error_suffix = '';
end

if isfield(monthly_maps,'uncertainties')&&isfield(monthly_maps.uncertainties,input_vtype)&&isfield(monthly_maps.uncertainties.(input_vtype),input_vname)
    error_types = fieldnames(monthly_maps.uncertainties.(input_vtype).(input_vname)); 
    for error_type_ix = 1:length(error_types) % loop through upper and lower bound errors
        error_type = error_types{error_type_ix};
        if nargin<9
            error_names = fieldnames(monthly_maps.uncertainties.(input_vtype).(input_vname).(error_type));
        end
        for err_ix = 1:length(error_names) % loop through error sources
            err_name = error_names{err_ix};
            monthly_maps.uncertainties.(output_vtype).(output_vname).(error_type).([err_name output_error_suffix]) = monthly_maps.uncertainties.(input_vtype).(input_vname).(error_type).(err_name) .* m + b;
        end
    end
else
    disp(['could not propagate errors from monthly_maps.uncertainties.' input_vtype '.' input_vname ' – variable not found' ])
end
