################################################################################
### Code for analyzing tuna larvae from PNMS samples
### Samples collected Oct 2022
### Analysis code written July 2023
### Updated February 2024 with RadSeq DNA IDs
################################################################################

# load packages
library(openxlsx)
library(here)

# read in the data tables:
photo_data<- read.csv(here("data", "PAL22_Tuna photo data.csv"), nrows=22)[,1:6]
photo_calibration<- read.xlsx(here("data", "PNMS_Calibration.xlsx"))
length_data<- read.table(here("data","LengthResults_July2023.txt"), header=TRUE)
locations<- read.xlsx(here("data", "PAL_2022_Plankton_Locations.xlsx"))
tow_data<- read.xlsx(here("data", "PAL_2022_Fish larvae_Additional tow data_July 2023.xlsx"),
                     rows = 5:53, colNames = FALSE)
names(tow_data)<- c("Sample.ID", "Site", "Date", "FlowIn", "TimeIn", "FlowOut",
                    "TimeOut", "Duration", "MaxDepth_mba", "MaxDepth_m",
                    "FlowRotations", "Distance_m", "Volume_m3", "Temperature_depth")
RADseq_IDs<- read.xlsx(here("data", "Palau_tuna_2bRAD_ID.xlsx"))

################################################################################
## Compare morphological and genetic IDs
################################################################################
# Fix a couple of column names in radseq dataframe:
names(RADseq_IDs)[1]<- "Sample.ID"
names(RADseq_IDs)[3]<- "DNA_ID"
# merge DNA ID's into the photo_data object
photo_data<- merge(photo_data, RADseq_IDs, by="Sample.ID")
# View it, summarize manually (see manuscript text)
View(photo_data)

# Take the genetic IDs as correct:
photo_data$Species<- photo_data$DNA_ID

################################################################################
## Calculate abundance of tunas
################################################################################

# Sum how many tuna larvae per station, by Species:
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
# Drop the shallow tows - they are excluded from this study
locations<- locations[locations$Tow=="D",]
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
length_data<- merge(length_data, photo_data, by.x="Image", by.y="Image_for_length",
                    all.y=TRUE)
length_data<- length_data[,c("Sample.ID", "Site", "Species", "Image",
                             "Magnification", "Length")]

# Merge in the calibration values:
length_data<- merge(length_data, photo_calibration)

# Calculate length in mm:
length_data$Length.mm<- length_data$Length/length_data$`pixels/(0.1.mm)`*0.1

# Calculate estimated ages
length_data$Age<- NA
# Thunnus, use PIPA curve:
I<- which(length_data$Species=="Thunnus albacares" | length_data$Species=="Thunnus obesus")
length_data$Age[I]<- round((length_data$Length.mm[I]-3.11)/0.37) + 2
# Skipjack, use PIPA curve:
I<- which(length_data$Species=="Katsuwonus pelamis")
length_data$Age[I]<- round((length_data$Length.mm[I]-3.38)/0.45) + 2
# Auxis, use curve from Laiz-Carrion 2013 (doi: 10.3354/meps10108)
I<- which(length_data$Species=="Auxis thazard")
length_data$Age[I]<- round((length_data$Length.mm[I]-1.524)/0.38) + 2

max(length_data$Age)

# dataframe with taxon, age, and catch location information:
# Separate "Site" into "Site" and "Station"
sampleid<- strsplit(as.character(length_data$Site), split='_')
length_data$Site<- sapply(sampleid, '[', 1)
length_data$Station<- sapply(sampleid, '[', 2)
# merge with tuna_all to add lat/lon and date information:
length_data<- unique(merge(length_data, tuna_all[,c("Site", "Station", "LATITUDE", "LONGITUDE", "Date", "Temperature_depth")],
                     by=c("Site", "Station")))
# keep the object that has all the larvae, including the ones that couldn't be measured:
length_data_all<- length_data
# drop the larvae that couldn't be measured:
I<- which(!is.na(length_data$Length))
length_data<- length_data[I,]
# save as .Rdata
save(file=here("results","PNMS_LengthAge.Rdata"), length_data)

################################################################################
## Map locations of catches with catch numbers
################################################################################
#The tows within each site are so close together that we need to plot one symbol
#per site. We also need to get the zero sites. Larvae were caught only in deep
#tows, so we'll just use those tows to calculate mean station location at each
#site.

# We're mapping things in QGIS, so this section will write out csv files for
# each taxon

# separate Site column into Site and Station for locations:
sampleid<- strsplit(as.character(locations$Site), split='_')
locations$Site<- sapply(sampleid, '[', 1)
locations$Station<- sapply(sampleid, '[', 2)
# aggregate by site:
site_locations<- aggregate(cbind(LATITUDE,LONGITUDE)~Site, data=locations, FUN=mean)
# save the site_locations object for mapping in QGIS:
write.csv(site_locations, file=here('data', 'Site_Locations_Summary.csv'))

# First, for tuna_pooled:
tuna_pooled_plotting<- aggregate(Nlarvae~Site, data=tuna_pooled, FUN=sum)
tuna_pooled_plotting<- merge(tuna_pooled_plotting, site_locations, all.y=TRUE)

# Repeat for tuna_all:
tuna_all_plotting<- aggregate(Nlarvae~Site+Species, data=tuna_all, FUN=sum)
tuna_all_plotting<- merge(tuna_all_plotting, site_locations, all.y=TRUE)

# Pooled larvae:
I<- which(is.na(tuna_pooled_plotting$Nlarvae))
tuna_pooled_plotting$Nlarvae[I]<- 0
write.csv(tuna_pooled_plotting, here('results', 'ForQGIS_tuna_pooled.csv'),
          row.names=FALSE)

# Thunnus albacares
I<- which(tuna_all_plotting$Species=="Thunnus albacares")
J<- which(site_locations$Site %in% tuna_all_plotting$Site[I])
yellowfin<- tuna_all_plotting[I,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
zero_stns<- site_locations[-J,]
zero_stns$Nlarvae<- 0
zero_stns<- zero_stns[,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
yellowfin<- rbind(yellowfin, zero_stns)
write.csv(yellowfin, here('results','ForQGIS_yellowfin.csv'))

# Thunnus obesus
I<- which(tuna_all_plotting$Species=="Thunnus obesus")
J<- which(site_locations$Site %in% tuna_all_plotting$Site[I])
bigeye<- tuna_all_plotting[I,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
zero_stns<- site_locations[-J,]
zero_stns$Nlarvae<- 0
zero_stns<- zero_stns[,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
bigeye<- rbind(bigeye, zero_stns)
write.csv(bigeye, here('results','ForQGIS_bigeye.csv'))

# Katsuwonus pelamis
I<- which(tuna_all_plotting$Species=="Katsuwonus pelamis")
J<- which(site_locations$Site %in% tuna_all_plotting$Site[I])
skipjack<- tuna_all_plotting[I,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
zero_stns<- site_locations[-J,]
zero_stns$Nlarvae<- 0
zero_stns<- zero_stns[,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
skipjack<- rbind(skipjack, zero_stns)
write.csv(skipjack, here('results','ForQGIS_skipjack.csv'))

# Auxis
I<- which(tuna_all_plotting$Species=="Auxis thazard")
J<- which(site_locations$Site %in% tuna_all_plotting$Site[I])
auxis<- tuna_all_plotting[I,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
zero_stns<- site_locations[-J,]
zero_stns$Nlarvae<- 0
zero_stns<- zero_stns[,c("Site","Nlarvae","LATITUDE",'LONGITUDE')]
auxis<- rbind(auxis, zero_stns)
write.csv(auxis, here('results','ForQGIS_auxis.csv'))

################################################################################
## Supplemental Data Table
################################################################################
head(length_data)

SuppTable<- merge(length_data_all, photo_data[,c("Sample.ID", "Piera/Chrissy.ID")])
SuppTable<- SuppTable[,c("Date", "Site", "Station", "LATITUDE", "LONGITUDE",
                         "Temperature_depth", "Sample.ID", "Piera/Chrissy.ID",
                          "Species", "Length.mm", "Age")]
write.csv(SuppTable, file=here("results", "PNMS_LarvaeDetailsTable.csv"),
          row.names=FALSE)


