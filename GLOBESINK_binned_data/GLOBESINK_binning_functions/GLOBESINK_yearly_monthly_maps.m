function [yearly_monthly_maps,lat_edges,lon_edges,years] = GLOBESINK_yearly_monthly_maps(monthly_bins,t_edges,lat_interval,lon_interval)
% [yearly_monthly_maps,lat_edges,lon_edges,years] = GLOBESINK_yearly_monthly_maps(monthly_bins,t_edges,lat_interval,lon_interval);
%

lat_edges = -90:lat_interval:90; %lat_mids = midpoints(lat_edges);
lon_edges = -180:lon_interval:180; %lon_mids = midpoints(lon_edges);
mmap = length(lat_edges)-1; nmap = length(lon_edges)-1;
nzbins = size(monthly_bins.total.PRES,1); % number of depth bins

% Create table for dates
dtable = table();
[dtable.yy,dtable.mm,dtable.dd] = datevec(t_edges(1:end-1)');

years = min(dtable.yy):max(dtable.yy);
nyears = length(years);
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
    yearly_monthly_maps.(vtype).(vname) = zeros(nzbins,mmap,nmap,12,nyears);
else
    yearly_monthly_maps.(vtype).(vname) = nan(nzbins,mmap,nmap,12,nyears);
end
for mix = 1:12
    for yix = 1:nyears
        thismonth = ((dtable.mm == mix) & (dtable.yy == years(yix)));
        thisv = v(:,thismonth,:);
        thisn = n(:,thismonth,:);
        thisv2 = reshape(thisv,nzbins,[]);
        thisn2 = reshape(thisn,nzbins,[]);
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
                        bad_vpixel = isnan(vpixel+npixel);
                        vpixel(bad_vpixel) = 0;
                        npixel(bad_vpixel) = 0;
                        if strcmp(vtype,'n') || strcmp(vtype,'nfilt')
                            yearly_monthly_maps.(vtype).(vname)(:,latix,lonix,mix,yix) = sum(vpixel,2);
                        else
                            %                 monthly_maps.(vtype).(vname)(latix,lonix,mix) = nanmean(vpixel,2);
                            yearly_monthly_maps.(vtype).(vname)(:,latix,lonix,mix,yix) = sum(vpixel.*npixel,2)./sum(npixel,2);
                        end
                    end
                end
            end
        end
    end
end
end
end
end
