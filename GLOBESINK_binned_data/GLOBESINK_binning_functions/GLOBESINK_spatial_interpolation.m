function monthly_maps_interpolated = GLOBESINK_spatial_interpolation(monthly_maps,min_n,lat_interval,lon_interval,lat_edges,lon_edges,vtypes,vnames)
% monthly_maps_interpolated = GLOBESINK_spatial_interpolation(monthly_maps,min_n,lat_interval,lon_interval,lat_edges,lon_edges,vtypes,vnames);

% min_n = 10;
%%
if nargin==6
    vtypes = fieldnames(monthly_maps);
    vtypes = vtypes(~ismember(vtypes,{'uncertainties'}));
end

[nz,nlat,nlon,nmonth] = size(monthly_maps.total.PRES);

%%
bath_struct = load_global_bathymetry;

deep_fraction_per_GLOBESINK_pixel = nan(nlat,nlon);
for lat_ix = 1:nlat
    glat_ixs = find(bath_struct.y>=lat_edges(lat_ix) & bath_struct.y<=lat_edges(lat_ix+1));
    for lon_ix = 1:nlon
        glon_ixs = find(bath_struct.x>=lon_edges(lon_ix) & bath_struct.x<=lon_edges(lon_ix+1));
        bath_subset = bath_struct.z(glat_ixs,glon_ixs);
        deep_fraction_per_GLOBESINK_pixel(lat_ix,lon_ix) = sum(bath_subset(:)<-1000)/length(bath_subset(:));
    end
end
land_mask = deep_fraction_per_GLOBESINK_pixel == 0;
%%
for vtix = 1:length(vtypes)
    vtype = vtypes{vtix};
    if nargin < 8
        vnames = fieldnames(monthly_maps.(vtype));
    else
        vnames = intersect(vnames,fieldnames(monthly_maps.(vtype)));
    end
    for vix = 1:length(vnames)
        vname = vnames{vix};
        monthly_maps_interpolated.(vtype).(vname) = nan(size(monthly_maps.(vtype).(vname)));
        for mix = 1:nmonth
            for zix = 1:nz
                c = squeeze(monthly_maps.(vtype).(vname)(zix,:,:,mix));
                n = squeeze(monthly_maps.nfilt.BBP700(zix,:,:,mix));
                if ~strcmp(vtype,'nfilt')&&~strcmp(vtype,'n')
                    if ismember(vtype,{'total','baseline','baseline2','baseline2_labile','baseline2_refractory','baseline_med'})
                        c(n<1) = nan;
                    else
                        c(n<min_n) = nan;
                    end
                end
                if sum(~isnan(c(:))) > 10
                    lon_window = round(24/lon_interval/2)*2-1;
                    lat_window = round(12/lat_interval/2)*2-1;
                    c_extended = c(:,[ceil(nlon*2/3):nlon 1:nlon 1:floor(nlon/3)]);
                    n_extended = running_sum_2D(~isnan(c_extended),lat_window,lon_window);
                    c_extended = running_nanmedian_2D(c_extended,lat_window,lon_window);
                    c_extended(n_extended<3) = nan;
                    [xmat, ymat] = meshgrid(1:size(c, 2), 1:size(c, 1));
                    [xmat_extended, ymat_extended] = meshgrid(1:size(c_extended, 2), 1:size(c_extended, 1));
                    xmat_extended = xmat_extended-length(ceil(nlon*2/3):nlon);
                    g = ~isnan(c_extended);
                    c_interp = griddata(xmat_extended(g), ymat_extended(g), c_extended(g),xmat,ymat, 'linear');
                    if ~isempty(c_interp)
                        % c = c_extended(:,length(ceil(nlon*2/3):nlon)+(1:nlon));
                        c_interp(repmat(midpoints(lat_edges)',1,length(lon_edges)-1)<-66 & isnan(c)) = nan;
                        c = c_interp;
                        c(land_mask) = nan;
                        monthly_maps_interpolated.(vtype).(vname)(zix,:,:,mix) = reshape(c,1,nlat,nlon,1);
                    end
                end
            end
        end
    end
end