%% Download currents from PNMS:
% Christina Hernandez
% 12/13/2023
% Updated 05/06/2024

cd /Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/
close all
clear all

%% Open the NetCDF via OPeNDAP

ncid = netcdf.open('http://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0');
varidTime = netcdf.inqVarID(ncid, 'time');
time = netcdf.getVar(ncid, varidTime);
varidLon = netcdf.inqVarID(ncid, 'lon');
lon = netcdf.getVar(ncid, varidLon);
varidLat = netcdf.inqVarID(ncid,'lat');
lat = netcdf.getVar(ncid,varidLat);
varidDepth = netcdf.inqVarID(ncid, 'depth');
depth = netcdf.getVar(ncid, varidDepth);

% dates for 2022: Sept 30 to October 22
time2 = datenum(time./24+datenum('2000-01-01 0:0:0'));
timelim = [datenum('2022-10-08 0:0:0'), datenum('2022-10-22 23:59:0')];
I = find(time2 >= timelim(1) & time2 <= timelim(2));
datatime = time2(I);
timestart = min(I)-1;
timecount = length(I);
timestride = 1;

% take data only at 25 m depth, which is the 10th depth layer:
depthstart = 10;
depthcount = 1;
depthstride = 1;

% latitude is in degrees N
latlim = [0, 14];
I = find(lat >= latlim(1) & lat <= latlim(2));
latstart = min(I)-1;
latstride = 1;
latcount = ceil(length(I)/latstride);
latz = lat(I(1:latstride:end));

% longitude is in degrees E
lonlim = [125, 140];
I = find(lon >= lonlim(1) & lon <= lonlim(2));
lonstart = min(I)-1;
lonstride = 1;
loncount = ceil(length(I)/lonstride);
lonz = lon(I(1:lonstride:end));

startcoords = [lonstart, latstart, depthstart, timestart];
countcoords = [loncount, latcount, depthcount, timecount];
stridecoords = [lonstride, latstride, depthstride, timestride];

% get eastward surface velocity
varidU = netcdf.inqVarID(ncid, 'water_u');
u = netcdf.getVar(ncid, varidU, startcoords, countcoords);
u(u==-30000) = NaN;
u = u*0.1; % scale factor is 0.001 for m/s, but if we multiply by 0.1, 
% then we get the velocity in cm/s

% get northward surface velocity
varidV = netcdf.inqVarID(ncid, 'water_v');
v = netcdf.getVar(ncid, varidV, startcoords, countcoords);
v(v==-30000) = NaN;
v = v*0.1; % scale factor is 0.001 for m/s, but if we multiply by 0.1, 
% then we get the velocity in cm/s

netcdf.close(ncid)

%% Taking some averages:

% collapse the variables to 3D, since we have 1 depth level
u = squeeze(u);
v = squeeze(v);

save('PNMS_HyCOM_2022.mat', 'u', 'v', 'datatime', 'lonz', 'latz');

u_mean = mean(u, 3, 'omitnan');
v_mean = mean(v, 3, 'omitnan');

toplot_u = u_mean(:);
toplot_v = v_mean(:);

[LON, LAT] = meshgrid(lonz, latz);
X = LON';
Y = LAT';
toplot_x = X(:);
toplot_y = Y(:);

quiver(toplot_x, toplot_y, toplot_u, toplot_v)

dataout = [toplot_x, toplot_y, toplot_u, toplot_v];
csvwrite('PNMS_Oct2022_currents.csv', dataout)