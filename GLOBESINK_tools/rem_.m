function newstr = rem_(oldstr)
% newstr = rem_(oldstr);
%
% removes underscores from a string and replaces with spaces

if iscell(oldstr)
    newstr = oldstr;
    for ii = 1:length(oldstr)
        newstr{ii}(oldstr{ii}=='_') = ' ';
    end
elseif iscategorical(oldstr)
    newstr = oldstr;
    for ii = 1:length(oldstr)
        this_str = char(newstr(ii));
        this_str(this_str=='_') = ' ';
        newstr(ii) = categorical({this_str});
    end
else
    newstr = oldstr;
    newstr(oldstr=='_') = ' ';
end
end