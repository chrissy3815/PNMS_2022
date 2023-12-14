%% This is the run script for making figures for the manuscript 
% Dec 13 2023
% It will read the trajectory files, read in the age data for aged fish, 
% and use the CTD data to scale the number of particles at the
% spawning location by the mortality function.

%% Read in all the trajectory data:

% set the working directory and add necessary folders to path:
cd /Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/backtracking/
addpath postproc
addpath input_pnms2022
addpath /Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/data

% read in the trajectory data:
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

%% Read in the release file to match up release file line and station number:

% release file:
relfile = dlmread('input_pnms2022/ReleaseFile_PNMS_Oct2022.txt', '\t');

%% Read in the age and station temperature data:

% Thunnus:
ageThunn = csvread('postproc/PNMS2022_ThunnusEstAges.csv');

% Katsuwonus:
ageKatsu = csvread('postproc/PNMS2022_KatsuwonusEstAges.csv');

% Auxis:
ageAuxis = csvread('postproc/PNMS2022_AuxisEstAges.csv');

%% Scaling parameters for mortality:
% temperature dependence according to Z = 0.0256 + 0.0123 * water_T

% calculate the mortality for station temperatures
ageThunn(:,4) = 0.0256 + 0.0123*ageThunn(:,3); 
ageKatsu(:,4) = 0.0256 + 0.0123*ageKatsu(:,3);
ageAuxis(:,4) = 0.0256 + 0.0123*ageAuxis(:,3);

%% Build up the data:

% Thunnus:
nfish = length(ageThunn(:,2));
lonThunn=[];
latThunn=[];
for ifish = 1:nfish
    iage = ageThunn(ifish,2);
    istn = ageThunn(ifish,1);
    istnZ = ageThunn(ifish, 4);
    % subset the simulation output to get the rows from that station:
    stnmtch = find(relfile(:,1)==istn, 1, 'first');
    isubdata = find(releaseout==stnmtch);
    % pull out the column corresponding to the correct age
    sublon = lonout(iage*2+1, isubdata);
    sublat = latout(iage*2+1, isubdata);
    % calculate the scaling parameter:
    scalingparam = round(1./exp(-(iage)*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonThunn = [lonThunn, repmat(sublon, 1, scalingparam)];
        latThunn = [latThunn, repmat(sublat, 1, scalingparam)];
    end
end

% Katsuwonus:
nfish = length(ageKatsu(:,2));
lonKatsu=[];
latKatsu=[];
for ifish = 1:nfish
    iage = ageKatsu(ifish,2);
    istn = ageKatsu(ifish,1);
    istnZ = ageKatsu(ifish, 4);
    % subset the simulation output to get the rows from that station:
    stnmtch = find(relfile(:,1)==istn, 1, 'first');
    isubdata = find(releaseout==stnmtch);
    % pull out the column corresponding to the correct age
    sublon = lonout(iage*2+1, isubdata);
    sublat = latout(iage*2+1, isubdata);
    % calculate the scaling parameter:
    scalingparam = round(1./exp(-(iage)*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonKatsu = [lonKatsu, repmat(sublon, 1, scalingparam)];
        latKatsu = [latKatsu, repmat(sublat, 1, scalingparam)];
    end
end

% Auxis:
nfish = length(ageAuxis(:,2));
lonAuxis=[];
latAuxis=[];
for ifish = 1:nfish
    iage = ageAuxis(ifish,2);
    istn = ageAuxis(ifish,1);
    istnZ = ageAuxis(ifish, 4);
    % subset the simulation output to get the rows from that station:
    stnmtch = find(relfile(:,1)==istn, 1, 'first');
    isubdata = find(releaseout==stnmtch);
    % pull out the column corresponding to the correct age
    sublon = lonout(iage*2+1, isubdata);
    sublat = latout(iage*2+1, isubdata);
    % calculate the scaling parameter:
    scalingparam = round(1./exp(-(iage)*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonAuxis = [lonAuxis, repmat(sublon, 1, scalingparam)];
        latAuxis = [latAuxis, repmat(sublat, 1, scalingparam)];
    end
end

% make the 2015 subrelease objects for plotting the release points: 
I = ismember(relfile(:,1), ageThunn(:,1));
relThunn = relfile(I,:);
I = ismember(relfile(:,1), ageKatsu(:,1));
relKatsu = relfile(I,:);
I = ismember(relfile(:,1), ageAuxis(:,1));
relAuxis = relfile(I,:);

%% Need to load the currents for plotting:

currents2022 = csvread('../data/PNMS_Oct2022_currents.csv');

%% Make the plots:

% taxa in separate plots:
figure1 = draw_spawn_loc_pnms(lonThunn, latThunn, relThunn, currents2022, 'PNMS2022_ThunnusRelSpawn_20231214.jpg');
figure2 = draw_spawn_loc_pnms(lonKatsu, latKatsu, relKatsu, currents2022, 'PNMS2022_KatsuRelSpawn_20231214.jpg');
figure3 = draw_spawn_loc_pnms(lonAuxis, latAuxis, relAuxis, currents2022, 'PNMS2022_AuxisRelSpawn_20231214.jpg');



