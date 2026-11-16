% function set_figure_text_size(fntsize)
% linewidth = 2;
AxisFontSize = 16;
LabelsFontsize = 16;
TitleFontsize = 18;

haxes = get(gcf, 'Children');
for number_of_axes = 1:length(haxes)
    if strcmp(get(haxes(number_of_axes),'type'),'axes')
        set(get(haxes(number_of_axes), 'xlabel'), 'Fontsize', LabelsFontsize);
        set(get(haxes(number_of_axes), 'ylabel'), 'Fontsize', LabelsFontsize);
        set(get(haxes(number_of_axes), 'zlabel'), 'Fontsize', LabelsFontsize);
        set(get(haxes(number_of_axes), 'title'), 'Fontsize', TitleFontsize);
        set(haxes(number_of_axes), 'Fontsize', AxisFontSize);
    %     hlines = get(haxes(i), 'Children');
    %     for j = 1:length(hlines)
    %         set(hlines(j),'linewidth', linewidth)
    %     end
    end
end