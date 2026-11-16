function monthly_bins_adjusted = apply_GLOBESINK_deep_offsets(monthly_bins,float_WMOs,deep_offset_tables)
% monthly_bins_adjusted = apply_GLOBESINK_deep_offsets(monthly_bins,float_WMOs,deep_offset_tables);

vtypes = fieldnames(deep_offset_tables);
monthly_bins_adjusted = monthly_bins;
for vtix = 1:length(vtypes)
    vtype = vtypes{vtix};
    vnames = fieldnames(deep_offset_tables.(vtype));
    for vix = 1:length(vnames)
        vname = vnames{vix};
        disp(['applying deep offsets for ' vtype '.' vname])
        for fix = 1:length(float_WMOs)
            this_WMO = float_WMOs(fix);
            table_ix = find(deep_offset_tables.(vtype).(vname).float_WMOs==this_WMO);
            if ~isempty(table_ix)
                this_offset = deep_offset_tables.(vtype).(vname).deep_offsets(table_ix);
                if ~isnan(this_offset)
                    monthly_bins_adjusted.(vtype).(vname)(:,:,fix) = monthly_bins.(vtype).(vname)(:,:,fix) + this_offset;
                end
            else
                disp(['float ' num2str(this_WMO) ' not found in offset table'])
            end
        end
    end
end