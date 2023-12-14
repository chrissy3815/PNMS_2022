################################################################################
### Code for analyzing tuna larvae from PNMS samples
### Samples collected Oct 2022
### Analysis code written July 2023
################################################################################

# load packages
library(openxlsx)
library(here)
library(oce)
library(ocedata)
library(rgdal)
library(ncdf4)
library(viridisLite)
library(sf)
library(raster)

# color function:
append_alpha  <- function(color, alpha) {
alpha_scaled  <- round(alpha*255)
alpha_hex  <- as.hexmode(alpha_scaled)
color_with_alpha  <- paste0(color, alpha_hex)

return(color_with_alpha)
}

# read in the data tables:
photo_data<- read.csv(here("data", "PAL22_Tuna photo data.csv"), nrows=22)
photo_calibration<- read.xlsx(here("data", "PNMS_Calibration.xlsx"))
length_data<- read.table(here("data","LengthResults_July2023.txt"), header=TRUE)
locations<- read.xlsx(here("data", "PAL_2022_Plankton_Locations.xlsx"))
tow_data<- read.xlsx(here("data", "PAL_2022_Fish larvae_Additional tow data_July 2023.xlsx"),
                     rows = 5:53, colNames = FALSE)
names(tow_data)<- c("Sample.ID", "Site", "Date", "FlowIn", "TimeIn", "FlowOut",
                    "TimeOut", "Duration", "MaxDepth_mba", "MaxDepth_m",
                    "FlowRotations", "Distance_m", "Volume_m3", "Temperature_depth")

################################################################################
## Calculate abundance of tunas
################################################################################

# Correct the tuna species that still have 2 possibilities (just give them the one we were more confident of for now)
photo_data$Species[photo_data$Species=="Katsuwonus/Thunnus"]<- "Katsuwonus"
photo_data$Species[photo_data$Species=="Thunnus/Katsuwonus"]<- "Thunnus"

# Sum how many tuna larvae per station, by species:
# (including the ones that couldn't be measured)
tuna_all<-aggregate(Sample.ID~Species+Site, photo_data[,c("Sample.ID", "Species", "Site")], FUN=length)
names(tuna_all)[3]<- "Nlarvae"
tuna_all$Tow<- "D" # manually inspected, all larvae were identified from "D" (deep) tows

# Sum of all tuna larvae pooled together (for calculating abundance)
tuna_pooled<- aggregate(Nlarvae~Site+Tow, data=tuna_all, FUN=sum)

# In locations, get net ID out of column "ID"
sampleid<- strsplit(as.character(locations$ID), split='_')
NetID<- sapply(sampleid, '[', 4)
locations$Tow<- NetID
# In tow_data, get net ID out of column "Sample.ID"
sampleid<- strsplit(as.character(tow_data$Sample.ID), split='_')
NetID<- sapply(sampleid, '[', 4)
tow_data$Tow<- NetID

# Add station information to tuna data:
tuna_all<- merge(tuna_all, locations, by=c("Site","Tow"), all.x=TRUE)
tuna_pooled<- merge(tuna_pooled, locations, by=c("Site", "Tow"), all.x=TRUE)

# Add tow depth/volume to tuna data:
tuna_all<- merge(tuna_all, tow_data[c("Site", "Tow", "MaxDepth_m", "Volume_m3", "Temperature_depth")],
                 by=c("Site","Tow"), all.x=TRUE)
tuna_pooled<- merge(tuna_pooled, tow_data[c("Site", "Tow", "MaxDepth_m", "Volume_m3", "Temperature_depth")],
                    by=c("Site", "Tow"), all.x=TRUE)

# Calculate abundances:
tuna_all$Abund_m2<- tuna_all$Nlarvae/tuna_all$Volume_m3*tuna_all$MaxDepth_m
tuna_pooled$Abund_m2<- tuna_pooled$Nlarvae/tuna_pooled$Volume_m3*tuna_pooled$MaxDepth_m

# Need to separate "Site" into "Site" and "Station"
sampleid<- strsplit(as.character(tuna_all$Site), split='_')
tuna_all$Site<- sapply(sampleid, '[', 1)
tuna_all$Station<- sapply(sampleid, '[', 2)
# Repeat for tuna_pooled
sampleid<- strsplit(as.character(tuna_pooled$Site), split='_')
tuna_pooled$Site<- sapply(sampleid, '[', 1)
tuna_pooled$Station<- sapply(sampleid, '[', 2)

################################################################################
## Calculate length and age
################################################################################

# Merge the photo and length data together:
length_data<- merge(length_data, photo_data, by.x="Image", by.y="Image_for_length")
length_data<- length_data[,c("Sample.ID", "Site", "Species", "Image",
                             "Magnification", "Length")]

# Merge in the calibration values:
length_data<- merge(length_data, photo_calibration)

# Calculate length in mm:
length_data$Length.mm<- length_data$Length/length_data$`pixels/(0.1.mm)`*0.1

# Calculate estimated ages
length_data$Age<- NA
# Thunnus, use PIPA curve:
I<- which(length_data$Species=="Thunnus")
length_data$Age[I]<- (length_data$Length.mm[I]-3.11)/0.37 + 2
# Skipjack, use PIPA curve:
I<- which(length_data$Species=="Katsuwonus")
length_data$Age[I]<- (length_data$Length.mm[I]-3.38)/0.45 + 2
# Auxis, use curve from Laiz-Carrion 2013 (doi: 10.3354/meps10108)
I<- which(length_data$Species=="Auxis")
length_data$Age[I]<- (length_data$Length.mm[I]-1.524)/0.38 + 2

max(length_data$Age)

# dataframe with taxon, age, and catch location information:
# Separate "Site" into "Site" and "Station"
sampleid<- strsplit(as.character(length_data$Site), split='_')
length_data$Site<- sapply(sampleid, '[', 1)
length_data$Station<- sapply(sampleid, '[', 2)
# merge with tuna_all to add lat/lon and date information:
length_data<- merge(length_data, tuna_all[,c("Site", "Station", "LATITUDE", "LONGITUDE", "Date", "Temperature_depth")])
# save as .Rdata:
save(file=here("results","PNMS_LengthAge.Rdata"), length_data)

################################################################################
## Plot locations of catches with catch numbers
################################################################################
# load the coastline
data("coastlineWorldFine")
# read in the bathymetry
ncid<- nc_open(here('data','Palau_Bathymetry', 'gebco_2023_n15.0_s0.0_w120.0_e145.0.nc'))
print(ncid)
bathylat<- ncvar_get(ncid, varid='lat')
bathylon<- ncvar_get(ncid, varid='lon')
bathy<- ncvar_get(ncid, varid='elevation')
nc_close(ncid)
# read in the PNMS shape file:
pnms_shp<- st_read(here('data', 'Palau_Shapefiles', 'PNMS.shp'), "PNMS")
pnms_boundaries<- spTransform(as_Spatial(st_geometry(pnms_shp)), "+proj=cea")

tuna_catch_plots<- function(filename, exes, whys, cexes){
  # re-order the points in increasing size:
  I<- order(cexes)
  exes<- exes[I]
  whys<- whys[I]
  cexes<- cexes[I]
  # initialize colors:
  colz<- viridisLite::mako(5, alpha=0.75)

  pdf(filename)
  mapPlot(coastlineWorldFine, longitudelim=c(128, 138), latitudelim=c(1, 12),
          projection="+proj=cea", grid=FALSE, lwd=2,
          axisStyle=5, lonlabels=seq(130, 136, 2), latlabels = c(4, 6, 8))
  mapContour(bathylon, bathylat, bathy,
             levels=c(-1000, -3000, -5000), drawlabels = FALSE,
             lwd=0.75, col=c('darkgrey', 'grey', 'lightgrey'))
  # Add PNMS boundaries
  plot(pnms_boundaries, add=TRUE, col=colz[5], border=colz[5])

  # plot larval catch data
  mapPoints(exes, whys, cex=sqrt(cexes), pch=19, col=colz[3])
  legend("bottomright", legend=as.character(unique(cexes)), title="N larvae",
         pch=19, col='grey', pt.cex=sqrt(unique(cexes)))

  # Add an inset map to show the location on the globe:
  plotInset('bottomleft',
            expr={plot(coastlineWorldFine, longitudelim=c(115, 160), latitudelim=c(-10, 20),
                       inset=TRUE, bg='white', axes=F, lwd=0.75)
              polygon(x=c(130, 130, 140, 140), y=c(5, 10, 10, 5), col='cyan')
            })

  dev.off()
}

# The tows within each site are so close together that we need to plot one
# symbol per site. First, for tuna_pooled:
tuna_pooled_plotting<- aggregate(Nlarvae~Site, data=tuna_pooled, FUN=sum)
Site_latz<- aggregate(LATITUDE~Site, data=tuna_pooled, FUN=mean)
Site_lonz<- aggregate(LONGITUDE~Site, data=tuna_pooled, FUN=mean)
tuna_pooled_plotting<- merge(tuna_pooled_plotting, Site_latz)
tuna_pooled_plotting<- merge(tuna_pooled_plotting, Site_lonz)

# Repeat for tuna_all:
tuna_all_plotting<- aggregate(Nlarvae~Site+Species, data=tuna_all, FUN=sum)
tuna_all_plotting<- merge(tuna_all_plotting, Site_latz)
tuna_all_plotting<- merge(tuna_all_plotting, Site_lonz)

# Pooled larvae:
tuna_catch_plots(here('results', 'PooledTunaLarvaeCatch.pdf'),
                 exes = tuna_pooled_plotting$LONGITUDE,
                 whys = tuna_pooled_plotting$LATITUDE,
                 cexes = tuna_pooled_plotting$Nlarvae)

# Thunnus
I<- which(tuna_all$Species=="Thunnus")
tuna_catch_plots(here('results', 'ThunnusLarvaeCatch.pdf'),
                 exes = tuna_all_plotting$LONGITUDE[I],
                 whys = tuna_all_plotting$LATITUDE[I],
                 cexes = tuna_all_plotting$Nlarvae[I])

# Katsuwonus
I<- which(tuna_all$Species=="Katsuwonus")
tuna_catch_plots(here('results', 'KatsuwonusLarvaeCatch.pdf'),
                 exes = tuna_all_plotting$LONGITUDE[I],
                 whys = tuna_all_plotting$LATITUDE[I],
                 cexes = tuna_all_plotting$Nlarvae[I])

# Auxis
I<- which(tuna_all$Species=="Auxis")
tuna_catch_plots(here('results', 'AuxisLarvaeCatch.pdf'),
                 exes = tuna_all_plotting$LONGITUDE[I],
                 whys = tuna_all_plotting$LATITUDE[I],
                 cexes = tuna_all_plotting$Nlarvae[I])

# Next steps:
# 1. Try to make a figure with all 3 taxa (different symbol shapes + colors)
