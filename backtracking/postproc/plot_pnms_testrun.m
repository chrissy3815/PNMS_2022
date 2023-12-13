%% This is the run script for checking if my test runs worked
% Nov 9 2023
% It will read the trajectory files, read in the age data for aged fish, 
% and use the CTD data to scale the number of particles at the
% spawning location by the mortality function.

%% Read in all the trajectory data at 10, and 25m:

directorypath = '/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/output/';
f = dir([directorypath,'traj_file_*']);
lonout=[];
latout=[];
releaseout=[];
for itraj = 1:length(f)
    filename = [directorypath,f(itraj).name];
    [lontemp, lattemp, ~, releasetemp] = readPIPAtraj(filename);
    lonout = [lonout, lontemp];
    latout = [latout, lattemp];
    releaseout=[releaseout releasetemp'];
end

%% Test plot:
% plot all the data from day 5 of tracking
lon_toplot = lonout(11,:);
lat_toplot = latout(11,:);

filename = '/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/output/backtracking_test_day10.jpg';
hfig = draw_spawn_loc_pnms(lon_toplot, lat_toplot, filename);





