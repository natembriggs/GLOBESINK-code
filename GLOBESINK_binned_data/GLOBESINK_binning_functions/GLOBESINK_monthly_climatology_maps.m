function [monthly_maps,lat_edges,lon_edges] = GLOBESINK_monthly_climatology_maps(monthly_bins,t_edges,lat_interval,lon_interval,bin_opts)
% monthly_maps = GLOBESINK_monthly_climatology_maps(monthly_bins,t_edges,lat_interval,lon_interval);
%

lat_edges = -90:lat_interval:90; %lat_mids = midpoints(lat_edges);
lon_edges = -180:lon_interval:180; %lon_mids = midpoints(lon_edges);
mmap = length(lat_edges)-1; nmap = length(lon_edges)-1;
nzbins = size(monthly_bins.total.PRES,1); % number of depth bins

% Create table for dates
dtable = table();
[dtable.yy,dtable.mm,dtable.dd] = datevec(t_edges(1:end-1)');
% recalc_monthly_maps = 0;
% if recalc_monthly_maps

vtypes = fieldnames(monthly_bins);
vtypes = vtypes(~ismember(vtypes,{'uncertainties'}));
%%
for vtix = 1:length(vtypes)
vtype = vtypes{vtix};
if isfield(monthly_bins,vtype) && isstruct(monthly_bins.(vtype))
vnames = fieldnames(monthly_bins.(vtype));
%%
for vix = 1:length(vnames)
    %%
vname = vnames{vix};
v = monthly_bins.(vtype).(vname);
if strcmp(vtype,'total')||strcmp(vtype,'n')
    n = monthly_bins.n.(vname);
else
    n = monthly_bins.nfilt.(vname);
end
if strcmp(vtype,'n') || strcmp(vtype,'nfilt')
    monthly_maps.(vtype).(vname) = zeros(nzbins,mmap,nmap,12);
else
    monthly_maps.(vtype).(vname) = nan(nzbins,mmap,nmap,12);
end
if strcmp(vtype,'PSD_slope') && strcmp(vname,'BBP700')
    v_lo = monthly_bins.uncertainties.(vtype).(vname).lower.precision;
    v_hi = monthly_bins.uncertainties.(vtype).(vname).upper.precision;
    monthly_maps.uncertainties.(vtype).(vname).lower.precision = nan(nzbins,mmap,nmap,12);
    monthly_maps.uncertainties.(vtype).(vname).upper.precision = nan(nzbins,mmap,nmap,12);
end

for mix = 1:12
    thismonth = dtable.mm == mix;
    thisv = v(:,thismonth,:);
    thisn = n(:,thismonth,:);
    thisv2 = reshape(thisv,nzbins,[]);
    thisn2 = reshape(thisn,nzbins,[]);
    if strcmp(vtype,'PSD_slope') && strcmp(vname,'BBP700')
        thisv_lo = v_lo(:,thismonth,:);
        thisv_hi = v_hi(:,thismonth,:);
        thisv_lo2 = reshape(thisv_lo,nzbins,[]);
        thisv_hi2 = reshape(thisv_hi,nzbins,[]);
    end
    for latix = 1:length(lat_edges)-1
        glat = is_between(monthly_bins.LATITUDE(:,thismonth,:),lat_edges(latix+[0 1]));
        if any(glat(:))
            %%
        for lonix = 1:length(lon_edges)-1
            glatlon = glat&is_between(monthly_bins.LONGITUDE(:,thismonth,:),lon_edges(lonix+[0 1]));
            if any(glatlon(:))
            glatlon2 = reshape(glatlon,1,[]);
%             gpixel = repmat(glatlon,nzbins,1);
            vpixel = thisv2(:,glatlon2);
            npixel = thisn2(:,glatlon2);
            bad_vpixel = isnan(vpixel+npixel) | isinf(vpixel); 
            if length(vtype)>=3 && strcmp(vtype(1:3),'var')
                bad_vpixel = bad_vpixel | npixel<2;
            end

                vpixel(bad_vpixel) = 0;
                npixel(bad_vpixel) = 0;
            if strcmp(vtype,'n') || strcmp(vtype,'nfilt') || ...
                        (length(vtype)>2 && strcmp(vtype((end-1):end),'_n'))
                % add together number of samples in bin
                monthly_maps.(vtype).(vname)(:,latix,lonix,mix) = sum(vpixel,2);
            elseif length(vtype)>=3 && strcmp(vtype(1:3),'var')
                % pooled variance
                gn = sum(npixel,2)>1;
                n_minus_one = npixel-1;
                monthly_maps.(vtype).(vname)(gn,latix,lonix,mix) = sum(vpixel(gn,:).*n_minus_one(gn,:),2)./ ...
                    sum(n_minus_one(gn,:),2);
                monthly_maps.(vtype).(vname)(~gn,latix,lonix,mix) = nan;
            elseif strcmp(vtype,'PSD_slope') && strcmp(vname,'BBP700')
                vpixel_lo = thisv_lo2(:,glatlon2);
                vpixel_hi = thisv_hi2(:,glatlon2);
                % inverse variance weighting for PSD slope mean and CI
                [mu_pool, ci_lo_pool, ci_hi_pool] = poolMeansIVW(vpixel, vpixel-vpixel_lo, vpixel+vpixel_hi, 0.05,2);
                monthly_maps.(vtype).(vname)(:,latix,lonix,mix) = mu_pool;
                monthly_maps.uncertainties.(vtype).(vname).lower.precision(:,latix,lonix,mix) = mu_pool-ci_lo_pool;
                monthly_maps.uncertainties.(vtype).(vname).upper.precision(:,latix,lonix,mix) = ci_hi_pool-mu_pool;
            else
%                 monthly_maps.(vtype).(vname)(latix,lonix,mix) = nanmean(vpixel,2);
                monthly_maps.(vtype).(vname)(:,latix,lonix,mix) = sum(vpixel.*npixel,2)./sum(npixel,2);
            end
            end
        end
        end
    end
end
end
end
end
%% extract bbr
min_n = 1;
monthly_maps_interpolated_bb = GLOBESINK_spatial_interpolation(monthly_maps,min_n,lat_interval,lon_interval,lat_edges,lon_edges,{'baseline2'},{'BBP700'});
bbr = min(min(monthly_maps_interpolated_bb.baseline2.BBP700,[],1),[],4);
monthly_maps.baseline2_refractory.BBP700 = repmat(bbr,nzbins,1,1,12);
monthly_maps.baseline2_labile.BBP700 = max(monthly_maps.baseline2.BBP700 - monthly_maps.baseline2_refractory.BBP700,0);
monthly_maps.baseline2_labile.BBP700(isnan(monthly_maps.baseline2.BBP700)) = nan;


%% get uncertainties for number of spikes
for vix = 1:length(bin_opts.vars_to_filter)
    vname = bin_opts.vars_to_filter{vix};
    for vtix = 1:length(vtypes)
        vtype = vtypes{vtix};
        if (length(vtype)>2 && strcmp(vtype((end-1):end),'_n'))
            [~,nspikes_upper] = poissonUpperBoundChi2(monthly_maps.(vtype).(vname), 0.05);
            [~,nspikes_lower] = poissonLowerBoundChi2(monthly_maps.(vtype).(vname), 0.05);
            monthly_maps.uncertainties.(vtype).(vname).upper.precision = nspikes_upper;
            monthly_maps.uncertainties.(vtype).(vname).lower.precision = nspikes_lower;
        end
    end
end
%% get uncertainties for mean and var
monthly_maps = GLOBESINK_get_spike_uncertainties(monthly_maps,bin_opts);
%% get mean diameters
size_suffices = {'','_nobig'};
monthly_maps = GLOBESINK_calculate_mean_ESD(monthly_maps,bin_opts,size_suffices);
%% get number concentrations
size_suffices = {'_small2','_medium2','_big2'};
monthly_maps = GLOBESINK_calculate_number_concentrations(monthly_maps,bin_opts,size_suffices);

