% This is the run script for making figures for the manuscript 
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

% Thunnus albacares:
ageYellowfin = csvread('postproc/PNMS2022_YellowfinEstAges.csv');

% Thunnus obesus:
ageBigeye = csvread('postproc/PNMS2022_BigeyeEstAges.csv');

% Katsuwonus:
ageKatsu = csvread('postproc/PNMS2022_KatsuwonusEstAges.csv');

% Auxis:
ageAuxis = csvread('postproc/PNMS2022_AuxisEstAges.csv');

%% Scaling parameters for mortality:
% temperature dependence according to Z = 0.0256 + 0.0123 * water_T

% calculate the mortality for station temperatures
ageYellowfin(:,4) = 0.0256 + 0.0123*ageYellowfin(:,3); 
ageBigeye(:,4) = 0.0256 + 0.0123*ageBigeye(:,3); 
ageKatsu(:,4) = 0.0256 + 0.0123*ageKatsu(:,3);
ageAuxis(:,4) = 0.0256 + 0.0123*ageAuxis(:,3);

%% Build up the data:

% Thunnus albacares:
nfish = length(ageYellowfin(:,2));
lonYellowfin=[];
latYellowfin=[];
for ifish = 1:nfish
    iage = ageYellowfin(ifish,2);
    istn = ageYellowfin(ifish,1);
    istnZ = ageYellowfin(ifish, 4);
    % subset the simulation output to get the rows from that station:
    stnmtch = find(relfile(:,1)==istn, 1, 'first');
    isubdata = find(releaseout==stnmtch);
    % pull out the column corresponding to the correct age
    sublon = lonout(iage*2+1, isubdata);
    sublat = latout(iage*2+1, isubdata);
    % calculate the scaling parameter:
    scalingparam = round(exp(iage*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonYellowfin = [lonYellowfin, repmat(sublon, 1, scalingparam)];
        latYellowfin = [latYellowfin, repmat(sublat, 1, scalingparam)];
    end
end

% Thunnus obesus:
nfish = length(ageBigeye(:,2));
lonBigeye=[];
latBigeye=[];
for ifish = 1:nfish
    iage = ageBigeye(ifish,2);
    istn = ageBigeye(ifish,1);
    istnZ = ageBigeye(ifish, 4);
    % subset the simulation output to get the rows from that station:
    stnmtch = find(relfile(:,1)==istn, 1, 'first');
    isubdata = find(releaseout==stnmtch);
    % pull out the column corresponding to the correct age
    sublon = lonout(iage*2+1, isubdata);
    sublat = latout(iage*2+1, isubdata);
    % calculate the scaling parameter:
    scalingparam = round(exp(iage*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonBigeye = [lonBigeye, repmat(sublon, 1, scalingparam)];
        latBigeye = [latBigeye, repmat(sublat, 1, scalingparam)];
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
    scalingparam = round(exp(iage*istnZ));
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
    scalingparam = round(exp(iage*istnZ));
    if (~isempty(sublon) && ~isempty(scalingparam))
        lonAuxis = [lonAuxis, repmat(sublon, 1, scalingparam)];
        latAuxis = [latAuxis, repmat(sublat, 1, scalingparam)];
    end
end

% make the subrelease objects for plotting the release points: 
I = ismember(relfile(:,1), ageYellowfin(:,1));
relYellowfin = relfile(I,:);
I = ismember(relfile(:,1), ageBigeye(:,1));
relBigeye = relfile(I,:);
I = ismember(relfile(:,1), ageKatsu(:,1));
relKatsu = relfile(I,:);
I = ismember(relfile(:,1), ageAuxis(:,1));
relAuxis = relfile(I,:);

%% Need to load the currents for plotting:

currents2022 = csvread('../data/PNMS_Oct2022_currents.csv');

% Calculate average currents

I = find(currents2022(:,1)>=133.5 & currents2022(:,1)<=134.5); % filter longitude
filtered_currents = currents2022(I,:);
I = find(filtered_currents(:,2)>=5.5 & filtered_currents(:,2)<=7); % filter latitude
filtered_currents = filtered_currents(I,:);

% calculate the magnitude at each point:
magz = sqrt(filtered_currents(:,3).^2 + filtered_currents(:,4).^2);
mean(magz)

%% Make the plots:

% taxa in separate plots:
figure1 = draw_spawn_loc_pnms(lonYellowfin, latYellowfin, relYellowfin, currents2022, 'PNMS2022_YellowfinRelSpawn_20240506.jpg');
set(gcf, 'Renderer', 'painters')
print('PNMS2022_YellowfinRelSpawn_20240506.eps', '-depsc2')
figure2 = draw_spawn_loc_pnms(lonBigeye, latBigeye, relBigeye, currents2022, 'PNMS2022_BigeyeRelSpawn_20240506.jpg');
set(gcf, 'Renderer', 'painters')
print('PNMS2022_BigeyeRelSpawn_20240506.eps', '-depsc2')
figure3 = draw_spawn_loc_pnms(lonKatsu, latKatsu, relKatsu, currents2022, 'PNMS2022_KatsuRelSpawn_20240506.jpg');
set(gcf, 'Renderer', 'painters')
print('PNMS2022_KatsuRelSpawn_20240506.eps', '-depsc2')
figure4 = draw_spawn_loc_pnms(lonAuxis, latAuxis, relAuxis, currents2022, 'PNMS2022_AuxisRelSpawn_20240506.jpg');
set(gcf, 'Renderer', 'painters')
print('PNMS2022_AuxisRelSpawn_20240506.eps', '-depsc2')

% Combined Thunnus plot:
relThunn = unique([relYellowfin; relBigeye], 'rows');
figure5 = draw_spawn_loc_pnms([lonYellowfin, lonBigeye], [latYellowfin, latBigeye], relThunn, currents2022, 'PNMS2022_ThunnusRelSpawn_20240506.jpg');
set(gcf, 'Renderer', 'painters')
print('PNMS2022_ThunnusRelSpawn_20240506.eps', '-depsc2')

