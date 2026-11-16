function g = is_between(varargin)
% g = is_between(x,start_end_matrix);
% or 
% g = is_between(x,starts,ends);
%
% start_end_matrix = [starts ends];
%
% finds points of x between "starts" and "ends"
% if "starts" and "ends" are vectors, finds points between ANY "start" and 
% its corresponding "end"

x = varargin{1};
switch length(varargin) 
    case 2
        start_end_matrix = varargin{2};
        starts = start_end_matrix(:,1);
        ends = start_end_matrix(:,2);
    case 3
        starts = varargin{2};
        ends = varargin{3};
end

g = x>=starts(1) & x<=ends(1);
for ii = 2:length(starts)
    g = g | (x>=starts(ii) & x<=ends(ii));
end

end