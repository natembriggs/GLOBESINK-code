function bin_structure = GLOBESINK_calculate_number_concentrations(bin_structure,bin_opts,size_suffices)
% bin_structure = GLOBESINK_calculate_mean_ESD(bin_structure,bin_opts,size_suffices)
%
% calculates mean diameter in µm via Briggs et al. (2013) variance-to-mean ratio
% method, from variance and mean of bbp in m^-1, volume in ml, 

%% get mean diameters
% size_suffices = {'_small2','_medium2','_big2'};
for vix = 1:length(bin_opts.size_vars)
    vname = bin_opts.size_vars{vix};
    this_n_measurements = (bin_structure.nfilt.(vname));
    this_V_sampled_L = this_n_measurements*(bin_opts.V/1000); % liters
    if isfield(bin_structure.total,vname)
        for size_ix = 1:length(size_suffices)
            size_suffix = size_suffices{size_ix};
            this_n_particles = (bin_structure.(['spikes' size_suffix '_n']).(vname));
            n_conc = this_n_particles./this_V_sampled_L; % L^-1
            bin_structure.(['n_concentration' size_suffix]).(vname) = n_conc;

            input_vtype = ['spikes' size_suffix '_n']; output_vtype = ['n_concentration' size_suffix];
            input_vname = vname; output_vname = vname;
            bin_structure = GLOBESINK_propagate_relative_errors(bin_structure,...
                input_vtype,input_vname,output_vtype,output_vname);
        end
    end
end

% bin_structure = GLOBESINK_propagate_relative_errors()

