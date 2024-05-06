function hFig = draw_spawn_loc(LONZ, LATZ, subrelease, currents, savefile)
%%%% This function is to make a map of spawning locations
%%%% The code in here is PNMS-specific, but can be adapted to other
%%%% regions
%%%% It uses 0.1 by 0.1 lat/lon boxes for the grid.

% This script was updated 2019-01-29 to make the color axis standardized
% and to set the aspect ratio to cos(4deg) for the PIPA plots

% set the limits for the histogram:
lons=(min(LONZ)-1:0.05:max(LONZ)+1)';
lats=(min(LATZ)-1:0.05:max(LATZ)+1)';
[LON,LAT]=meshgrid(lons,lats);
% Make a spatial histogram:
LATZ(LATZ>2e5)=NaN;
LONZ(LONZ>2e5)=NaN;
Pointz = [LONZ',LATZ'];
numlarvae = hist3(Pointz,'Edges',{lons lats})';

num_colors=200;

% toplot = numlarvae./sum(sum(numlarvae));
toplot = numlarvae./max(max(numlarvae));
toplot(toplot==0)=NaN;
toplot=log(toplot);
% minval=-21;
% maxval=-3;
minval=min(min(toplot));
maxval=max(max(toplot));

hFig=figure;
% set(hFig,'Visible','off');
set(hFig,'units','inches');
% set(hFig,'Position',[0 0.5 18.6 10.3]);
set(hFig,'PaperPositionMode','auto');

% Bathymetry:
ncid = netcdf.open('/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/data/Palau_Bathymetry/gebco_2023_n15.0_s0.0_w120.0_e145.0.nc', 'NC_NOWRITE');
% get the latitude values
bathylatID = netcdf.inqVarID(ncid, 'lat');
bathylat = netcdf.getVar(ncid, bathylatID);
% get the longitude values
bathylonID = netcdf.inqVarID(ncid, 'lon');
bathylon = netcdf.getVar(ncid, bathylonID);
% get the elevation values
bathyID = netcdf.inqVarID(ncid, 'elevation');
bathy = netcdf.getVar(ncid, bathyID, 'double');
netcdf.close(ncid)
% subset the bathymetry:
I = find(bathylon>=130 & bathylon<=135);
J = find(bathylat>=5 & bathylat<=12);
bathylat = bathylat(J);
bathylon = bathylon(I);
bathy = bathy(I,J);
% plot the bathymetry:
contour(bathylon, bathylat, bathy', [0 0], 'Color', [.2 .2 .2])
hold on

% bin the currents into 1/4 degree bins:
% longitude:
I = find(currents(:,1)-floor(currents(:,1))<0.25);
J = find(currents(:,1)-floor(currents(:,1))>=0.25 & currents(:,1)-floor(currents(:,1))<0.5);
K = find(currents(:,1)-floor(currents(:,1))>=0.5 & currents(:,1)-floor(currents(:,1))<0.75);
L = find(currents(:,1)-floor(currents(:,1))>=0.75 & currents(:,1)-floor(currents(:,1))<1);

currents(I,1) = floor(currents(I,1));
currents(J,1) = floor(currents(J,1))+0.25;
currents(K,1) = floor(currents(K,1))+0.5;
currents(L,1) = floor(currents(L,1))+0.75;

% latitude:
I = find(currents(:,2)-floor(currents(:,2))<0.25);
J = find(currents(:,2)-floor(currents(:,2))>=0.25 & currents(:,2)-floor(currents(:,2))<0.5);
K = find(currents(:,2)-floor(currents(:,2))>=0.5 & currents(:,2)-floor(currents(:,2))<0.75);
L = find(currents(:,2)-floor(currents(:,2))>=0.75 & currents(:,2)-floor(currents(:,2))<1);

currents(I,2) = floor(currents(I,2));
currents(J,2) = floor(currents(J,2))+0.25;
currents(K,2) = floor(currents(K,2))+0.5;
currents(L,2) = floor(currents(L,2))+0.75;

lonbins = unique(currents(:,1));
latbins = unique(currents(:,2));
currents2=[];

for i = 1:length(lonbins)
    I = find(currents(:,1)==lonbins(i));
   for j = 1:length(latbins)
       J = find(currents(:,2)==latbins(j));
       
       K = find(ismember(J,I));
       
       meancurr_u = nanmean(currents(J(K),3));
       meancurr_v = nanmean(currents(J(K),4));
       
       temprow = [lonbins(i), latbins(j), meancurr_u, meancurr_v];
       currents2 = [currents2; temprow];
       
   end
end

currents = currents2;

% subset the currents to just the area we want to plot:
I = find(currents(:,1)>=131 & currents(:,1)<=136); % filter longitude
currents = currents(I,:);
I = find(currents(:,2)>=5 & currents(:,2)<=10); % filter latitude
currents = currents(I,:);

% Append a dummy entry to the end of currents to be the scale bar:
newrow = [134.6, 5.75, 50, 0];
currents = [currents; newrow];

% plot the currents:
%q = quiver(currents2(:,1), currents2(:,2), currents2(:,3), currents2(:,4));
q = quiver(currents(:,1), currents(:,2), currents(:,3), currents(:,4), 2);
q.Color = [0.7 0.7 0.7];
hold on

% add the PNMS boundary:
S = shaperead('/Users/chrissy/PalauNationalMarineSanctuary/PNMS_2022/data/Palau_Shapefiles/PNMS.shp');
plot(S.X, S.Y, '-', 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);

% add the spawning output color contours
contourlevels = linspace(minval,maxval,num_colors);
contourf(LON,LAT,toplot,contourlevels,'linestyle','none');
wg = jet;
colormap(wg);
c = colorbar('FontSize', 18);
caxis([minval maxval]);
c.Label.String = 'log10[Relative Spawning Output]';
hold on

% add the release points
plot(subrelease(:,2), subrelease(:,3), '^k', 'MarkerSize', 6)

% set the axes to be pretty
axis image
axis([132 135 5.5 9])
pbaspect([0.9975 1 1])
s = sprintf('Longitude (%cE)', char(176));
xlabel(s, 'FontSize', 18)
s = sprintf('Latitude (%cN)', char(176));
ylabel(s, 'FontSize', 18)
set(gca, 'FontSize', 18)
% save as a jpeg
print('-djpeg',savefile); 


end
