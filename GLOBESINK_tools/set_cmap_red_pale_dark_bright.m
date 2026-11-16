function set_cmap_red_pale_dark_bright()
% colormap hsv
% hsvmap = colormap;
% %%
% a = hsvmap;
% a(47:end,1) = hsvmap(47:end,3);
% colormap(a)
% figure(49);clf
% colorbar
% b = [a([1:12 14 16 20 23 27 29 30:36],:); mean(a(37:38,:),1);  a(39:end,:)];
% colormap(b)
%%
ncolors = 40;
off_start= 0.95; off_end = 0;
on_start = 1; on_end = 0.5;
off_scale = off_start:(off_end-off_start)/ncolors:off_end;
on_scale = on_start:(on_end-on_start)/ncolors:on_end;

ncolors = 40;
off_start= 0; off_end = 0;
on_start = 0.5; on_end = 1;
off_scale = [off_scale(1:end-1) zeros(1,ncolors+1)];
on_scale = [on_scale(1:end-1) on_start:(on_end-on_start)/ncolors:on_end];

c = [on_scale' off_scale' off_scale'];
% tmp = ([0 0.3 0.47 0.6 0.7 0.75 0.8 0.85 0.9 0.95 1])';
% %
% c = ones(length(tmp)*2-1,3);
% c(length(tmp):length(tmp)*2-1,2:3) = repmat(tmp(end:-1:1),1,2);
% c(1:length(tmp),1:2) = repmat(tmp,1,2);
%
colormap(gca,c);