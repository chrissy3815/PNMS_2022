function hFig = draw_spawn_loc(LONZ, LATZ, savefile)
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

% % Bathymetry:
% ncid = netcdf.open('/Users/chrissy/JointProgram/PIPA/PIPA_Bathymetry/GEBCO_2014_2D_-180.0_-10.0_-150.0_10.0.nc', 'NC_NOWRITE');
% % get the latitude values
% bathylatID = netcdf.inqVarID(ncid, 'lat');
% bathylat = netcdf.getVar(ncid, bathylatID);
% % get the longitude values
% bathylonID = netcdf.inqVarID(ncid, 'lon');
% bathylon = netcdf.getVar(ncid, bathylonID);
% % switch to degrees east to match above
% bathylon = bathylon+360;
% % get the elevation values
% bathyID = netcdf.inqVarID(ncid, 'elevation');
% bathy = netcdf.getVar(ncid, bathyID, 'double');
% netcdf.close(ncid)
% % subset the bathymetry:
% I = find(bathylon>=183 & bathylon<=193);
% J = find(bathylat>=-8 & bathylat<=2);
% bathylat = bathylat(J);
% bathylon = bathylon(I);
% bathy = bathy(I,J);
% % plot the bathymetry:
% contour(bathylon, bathylat, bathy', [-5000 -3000 -1000 0], 'Color', [.2 .2 .2])
% hold on

% bin the currents into 1/2 degree bins:
% I = find(currents(:,1)-floor(currents(:,1))<0.5);
% currents(I,1) = floor(currents(I,1));
% J = find(currents(:,2) - floor(currents(:,2))<0.5);
% currents(J,2)= floor(currents(J,2));
% K = find(currents(:,1)-floor(currents(:,1))>0.5);
% currents(K,1)= floor(currents(K,1)) + 0.5;
% L= find(currents(:,2)-floor(currents(:,2))>0.5);
% currents(L,2)= floor(currents(L,2)) + 0.5;
% 
% lonbins = unique(currents(:,1));
% latbins = unique(currents(:,2));
% currents2=[];
% 
% for i = 1:length(lonbins)
%     I = find(currents(:,1)==lonbins(i));
%    for j = 1:length(latbins)
%        J = find(currents(:,2)==latbins(j));
%        
%        K = find(ismember(J,I));
%        
%        meancurr_u = nanmean(currents(J(K),3));
%        meancurr_v = nanmean(currents(J(K),4));
%        
%        temprow = [lonbins(i), latbins(j), meancurr_u, meancurr_v];
%        currents2 = [currents2; temprow];
%        
%    end
% end
% 
% % plot the currents:
% q = quiver(currents2(:,1), currents2(:,2), currents2(:,3), currents2(:,4));
% q.Color = [0.7 0.7 0.7];
% hold on
% 
% % add the PIPA boundary:
% S = shaperead('/Users/chrissy/JointProgram/PIPA/CMS/worldheritagemarineprogramme/worldheritagemarineprogramme.shp');
% plot(S.X+360, S.Y, '-', 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);

% add the spawning output color contours
contourlevels = linspace(minval,maxval,num_colors);
contourf(LON,LAT,toplot,contourlevels,'linestyle','none');
wg = jet;
colormap(wg);
c = colorbar('FontSize', 18);
caxis([minval maxval]);
c.Label.String = 'Relative Spawning Output (log-scale)';
hold on

% add the release points
% plot(subrelease(:,2), subrelease(:,3), '^k', 'MarkerSize', 6)

% set the axes to be pretty
axis image
axis([134.4 135 8.6 8.9])
pbaspect([0.9975 1 1])
s = sprintf('Longitude (%cE)', char(176));
xlabel(s, 'FontSize', 18)
s = sprintf('Latitude (%cN)', char(176));
ylabel(s, 'FontSize', 18)
set(gca, 'FontSize', 18)
% save as a jpeg
print('-djpeg',savefile); 


end
