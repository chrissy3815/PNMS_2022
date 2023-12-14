%% This is the run script for checking if my test runs worked
% Nov 9 2023
% It will read the trajectory files and plot one day of data.

%% Read in all the trajectory data:

% set the working directory and add necessary folders to path:
cd /Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/
addpath postproc

% read in the trajectory data:
directorypath = '/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/test_run_output/';
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

filename = '/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/test_run_output/test_plot.jpg';
hfig = draw_spawn_loc_pnms(lon_toplot, lat_toplot, filename);





