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
tuna_all<- merge(tuna_all, tow_data[c("Site", "Tow", "MaxDepth_m", "Volume_m3")],
                 by=c("Site","Tow"), all.x=TRUE)
tuna_pooled<- merge(tuna_pooled, tow_data[c("Site", "Tow", "MaxDepth_m", "Volume_m3")],
                    by=c("Site", "Tow"), all.x=TRUE)

# Calculate abundances:
tuna_all$Abund_m2<- tuna_all$Nlarvae/tuna_all$Volume_m3*tuna_all$MaxDepth_m
tuna_pooled$Abund_m2<- tuna_pooled$Nlarvae/tuna_pooled$Volume_m3*tuna_pooled$MaxDepth_m

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

################################################################################
## Plot locations of catches with catch numbers
################################################################################
# load the coastline
data("coastlineWorldFine")

#setEPS()
#postscript('1_AcrossYears/StationLocations2015-17_20190621.eps')
mapPlot(coastlineWorldFine, longitudelim=c(130, 140), latitudelim=c(5, 10),
        projection="+proj=cea", grid=FALSE, axes=TRUE, cex.axis=1)
mapContour(bathylon, bathylat, bathy,
           levels=c(-1000, -3000, -5000),
           lwd=0.75, col='grey')
# Add 2015 stations:
mapPoints(totaltuna2015$LonDEC, totaltuna2015$LatDEC, pch=5, cex=1.1)
mapPoints(totaltuna2016$LonDEC, totaltuna2016$LatDEC, pch=2, cex=1.1)
mapPoints(totaltuna2017$LonDEC, totaltuna2017$LatDEC, pch=3, cex=1.1)
# as text:
# text(totaltuna2015$LonDEC, totaltuna2015$LatDEC, totaltuna2015$Station, cex=0.75)
# text(totaltuna2016$LonDEC, totaltuna2016$LatDEC, totaltuna2016$Station, cex=0.75, col='red')
# text(totaltuna2017$LonDEC, totaltuna2017$LatDEC, totaltuna2017$Station, cex=0.75, col='blue')

# Add PIPA polygon
mapLines(pipa_boundaries$long,pipa_boundaries$lat, lwd=2)
# legend("bottomright", legend=c("2015", "2016", "2017"), pch=c(5,2,3), cex=1.1)
mapScalebar("topleft")

