function monthly_maps = GLOBESINK_generate_relative_uncertainty(monthly_maps,vtype,vname,error_name,upper_relative_uncertainty,lower_relative_uncertainty)
% monthly_maps = GLOBESINK_generate_relative_uncertainty(monthly_maps,vtype,vname,error_name,upper_relative_uncertainty,lower_relative_uncertainty)
%
% propogates relative uncertainties from variable

if isfield(monthly_maps,vtype)&&isfield(monthly_maps.(vtype),vname)
    v = monthly_maps.(vtype).(vname);
    monthly_maps.uncertainties.(vtype).(vname).upper.(error_name) = v * (upper_relative_uncertainty-1);
    monthly_maps.uncertainties.(vtype).(vname).lower.(error_name) = v * (1-lower_relative_uncertainty);
else
    disp(['could not generate errors from monthly_maps.' vtype '.' vname '. variable not found' ])
end
