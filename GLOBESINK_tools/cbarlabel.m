function [cbar_handle, label_handle] = cbarlabel(label)
% [cbar_handle, label_handle] = cbarlabel(label)
% 
% INPUT: string (ylabel of colorbar)
% OUTPUT: handle of colorbar and colorbar ylabel

cbar_handle = colorbar;
label_handle = get(cbar_handle,'ylabel');
set(label_handle,'string',label)

end