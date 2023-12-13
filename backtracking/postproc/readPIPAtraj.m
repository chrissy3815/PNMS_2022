function [lon, lat, releasedate, releaseline, status, depth, time] = readPIPAtraj(traj_filename)

%% read in the trajectory data

% open trajectory file
ncid = netcdf.open(traj_filename,'NC_NOWRITE');
% Get the values of time
varidTime = netcdf.inqVarID(ncid,'time');
time = netcdf.getVar(ncid,varidTime);
% Get the values of Longitude
varidLon = netcdf.inqVarID(ncid,'lon');
lon = netcdf.getVar(ncid,varidLon);
% Get the values of Latitude
varidLat = netcdf.inqVarID(ncid,'lat');
lat = netcdf.getVar(ncid,varidLat);
% Get the values of depths
varidDepth = netcdf.inqVarID(ncid,'depth');
depth = netcdf.getVar(ncid,varidDepth);
% Get the values of status
varidStatus = netcdf.inqVarID(ncid,'exitcode');
status = netcdf.getVar(ncid,varidStatus);
% Get the values of release date (in julian)
varidrel = netcdf.inqVarID(ncid,'releasedate');
releasedate = netcdf.getVar(ncid,varidrel);
% Get the values of release line number
varidLine = netcdf.inqVarID(ncid, 'location');
releaseline = netcdf.getVar(ncid, varidLine);
%close nestfile
netcdf.close(ncid);

lat(lat>999) = NaN;
lon(lon>999) = NaN;

end