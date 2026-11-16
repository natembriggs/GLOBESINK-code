function bin_structure = GLOBESINK_calculate_mean_ESD(bin_structure,bin_opts,size_suffices)
% bin_structure = GLOBESINK_calculate_mean_ESD(bin_structure,bin_opts,size_suffices)
%
% calculates mean diameter in µm via Briggs et al. (2013) variance-to-mean ratio
% method, from variance and mean of bbp in m^-1, volume in ml, 

%% get mean diameters
% size_suffices = {'','_nobig'};
for vix = 1:length(bin_opts.size_vars)
    vname = bin_opts.size_vars{vix};
    if isfield(bin_structure.total,vname)
        for size_ix = 1:length(size_suffices)
            size_suffix = size_suffices{size_ix};
            this_var = (bin_structure.(['var' size_suffix]).(vname)-bin_opts.bbp_var_blank);
            this_mean = (bin_structure.(['baseline_med' size_suffix]).(vname)+bin_structure.(['spikes_med' size_suffix]).(vname)-bin_opts.bbp_blank);
            this_var(this_var<0) = nan;
            this_mean(this_mean<=0) = nan;
            size = sqrt(4/pi*this_var./this_mean*bin_opts.V/bin_opts.Q/100)*10000; % sqrt([1/m]/100[cm/m]*cm^3)*10000[µm/cm]
            bin_structure.(['D_mean' size_suffix]).(vname) = size;

            try
                this_var_upper = this_var + bin_structure.uncertainties.(['var' size_suffix]).(vname).upper.precision;
                this_var_lower = this_var - bin_structure.uncertainties.(['var' size_suffix]).(vname).lower.precision;
                this_mean_upper = this_mean + bin_structure.uncertainties.(['spikes_med' size_suffix]).(vname).upper.precision;
                this_mean_lower = this_mean - bin_structure.uncertainties.(['spikes_med' size_suffix]).(vname).lower.precision;

                size_upper = sqrt(4/pi*this_var_upper./this_mean_upper*bin_opts.V/bin_opts.Q/100)*10000;
                size_lower = sqrt(4/pi*this_var_lower./this_mean_lower*bin_opts.V/bin_opts.Q/100)*10000;

                bin_structure.uncertainties.(['D_mean' size_suffix]).(vname).upper.precision = size_upper - size;
                bin_structure.uncertainties.(['D_mean' size_suffix]).(vname).lower.precision = size - size_lower;
            catch
                disp(['could not calculate uncertainties for vname: ' vname ', size_suffix: ' size_suffix])
            end
        end
    end
end
