function [zenith,sorad] = get_sun_zenith_angle(mtime,lat,lon)
% zenith = get_sun_zenith_angle(mtime,lat,lon);

[Y,~,~] = datevec(mtime);
yd = mtime-datenum(Y,1,0); % as used for the published GLOBESINK v1.0 build (13 May 2026). soradna1's yearday
% is 0.0 at 1 Jan 00:00, so this is one day late; corrected to datenum(Y,1,1) on 2026-10-01 for later product
% versions. Kept here so this release reproduces the published night-only variables.

[zenith,sorad] = soradna1(yd,Y,-lon,lat);