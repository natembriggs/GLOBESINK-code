function bin_structure = GLOBESINK_get_spike_uncertainties(bin_structure,bin_opts)
% bin_structure = GLOBESINK_get_spike_uncertainties(bin_structure,bin_opts);
%
% calculates uncertainty bounds of mean (and if applicable variance) for
% specified variable types. requires estimates of number concentrations and
% PSD slopes and their uncertainties.

spike_uncertainty_vtypes = fieldnames(bin_opts.diameter_limits_mm);
size_vars = bin_opts.size_vars;

for vix = 1:length(size_vars)
    vname = size_vars{vix};
    if isfield(bin_structure.total,vname) && isfield(bin_structure.uncertainties.PSD_slope,vname)
        for vtix = 1:length(spike_uncertainty_vtypes)
            %%
            vtype = spike_uncertainty_vtypes{vtix};

            bbp_measured = bin_structure.(vtype).(vname);
            b_hat = bin_structure.PSD_slope.(vname);
            b_lo_fit = b_hat - bin_structure.uncertainties.PSD_slope.(vname).lower.precision;
            b_hi_fit = b_hat + bin_structure.uncertainties.PSD_slope.(vname).upper.precision;

            Dmin = bin_opts.diameter_limits_mm.(vtype)(1); Dmax = bin_opts.diameter_limits_mm.(vtype)(2);
            nsamples = bin_structure.nfilt.(vname);
            switch vtype
                case 'spikes_med'
                    nparticles = bin_structure.spikes2_n.(vname) + bin_structure.spikes_big2_n.(vname);
                case 'spikes_med_nobig'
                    nparticles = bin_structure.spikes2_n.(vname);
                otherwise
                    nparticles = bin_structure.([vtype '_n']).(vname);
            end
            [n_hi,nmiss_hi] = poissonUpperBoundChi2(nparticles, 0.05); [n_lo,nmiss_lo] = poissonLowerBoundChi2(nparticles, 0.05);

            % intersection with literature bounds
            b_lo = max(b_lo_fit,bin_opts.PSD_slope_lit_range(1)); b_hi = min(b_hi_fit,bin_opts.PSD_slope_lit_range(2));
            b_mid = (b_lo+b_hi)/2;

            [dA_hi, dVar_hi] = psdAreaStats(Dmin, Dmax, b_lo, nmiss_hi./nsamples, bin_opts.V); % upper add
            [dA_lo, dVar_lo] = psdAreaStats(Dmin, Dmax, b_lo, nmiss_lo./nsamples, bin_opts.V); % lower add
            [A_hi, Var_hi] = psdAreaStats(Dmin, Dmax, b_lo, n_hi./nsamples, bin_opts.V); % upper bound
            [A_lo, Var_lo] = psdAreaStats(Dmin, Dmax, b_hi, n_lo./nsamples, bin_opts.V); % lower bound

            % convert area concentration (mm^2/ml) to bbp (m^-1)
            CF = bin_opts.Q; % conversion factor for units and Qbb
            dbbp_hi = dA_hi * CF; dbbp_lo = dA_lo * CF;
            bbp_hi = A_hi * CF; bbp_lo = A_lo * CF;
            % get alternative lower bounds
            dbbp_lo2 = bbp_measured-bbp_lo;
            disp([vname vtype ' altlow ratio – ' ...
                num2str(sum(dbbp_lo2(:)<dbbp_lo(:))) ':' num2str(sum(dbbp_lo2(:)>=dbbp_lo(:)))])
            dbbp_lo = min(dbbp_lo,dbbp_lo2);
            bin_structure.uncertainties.(vtype).(vname).upper.precision = dbbp_hi;
            bin_structure.uncertainties.(vtype).(vname).lower.precision = dbbp_lo;
            switch vtype
                case {'spikes_med','spikes_med_nobig'}
                    vt_suffix = vtype(11:end);
                    bbp_var_measured = bin_structure.(['var' vt_suffix]).(vname);
                    % convert area concentration variance (µm/ml)^2 to bbp variance (m^-1)^2
                    dVar_bbp_hi = dVar_hi * CF^2; dVar_bbp_lo = dVar_lo * CF^2;
                    Var_bbp_hi = Var_hi * CF^2; Var_bbp_lo = Var_lo * CF^2;
                    % get alternative lower bounds
                    dVar_bbp_lo2 = bbp_var_measured-Var_bbp_lo;
                    disp([vname vtype ' altlow var ratio – ' ...
                        num2str(sum(dVar_bbp_lo2(:)<dVar_bbp_lo(:))) ':' num2str(sum(dVar_bbp_lo2(:)>=dVar_bbp_lo(:)))])
                    dVar_bbp_lo = min(dVar_bbp_lo,dVar_bbp_lo2);
                    bin_structure.uncertainties.(['var' vt_suffix]).(vname).upper.precision = dVar_bbp_hi;
                    bin_structure.uncertainties.(['var' vt_suffix]).(vname).lower.precision = dVar_bbp_lo;
            end
        end
    end
end