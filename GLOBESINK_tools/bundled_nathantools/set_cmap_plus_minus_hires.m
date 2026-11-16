function set_cmap_plus_minus_hires()

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
tmp = ([0 0.3 0.47 0.6 0.7 0.75 0.8 0.85 0.9 0.95 1])';
l1 = length(tmp);
l2 = l1*2-1;
tmp2 = nan(l2,1);
tmp2(1:2:end) = tmp;
tmp2(2:2:end-1) = (tmp(1:end-1)+tmp(2:end))/2;

tmp = tmp2;
%
c = ones(length(tmp)*2-1,3);
c(length(tmp):length(tmp)*2-1,2:3) = repmat(tmp(end:-1:1),1,2);
c(1:length(tmp),1:2) = repmat(tmp,1,2);
% c(ceil(length(c)/2),:) = [0.975 0.975 0.975];
%
colormap(gca,c)