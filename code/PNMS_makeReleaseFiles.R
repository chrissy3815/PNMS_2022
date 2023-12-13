################################################################################
### Code to make release files for PNMS larval backtracking
### Chrissy Hernandez
### Nov 2023
################################################################################

# The release file needs to have one release site for each positive station

# load packages:
library(openxlsx)
library(here)
library(chron)

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
tow_data$TimeMidTow<- apply(tow_data[,c("TimeIn", "TimeOut")], MARGIN=1, FUN=mean, na.rm=TRUE)

################################################################################
## Find all the positive catch locations
################################################################################

# Sum how many tuna larvae per station, by species:
# (including the ones that couldn't be measured)
tuna_all<-aggregate(Sample.ID~Species+Site, photo_data[,c("Sample.ID", "Species", "Site")], FUN=length)
names(tuna_all)[3]<- "Nlarvae"
tuna_all$Tow<- "D" # manually inspected, all tuna larvae were identified from "D" (deep) tows

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

# Add time of the tow to tuna data:
tuna_all<- merge(tuna_all, tow_data[c("Site", "Tow", "TimeMidTow", "MaxDepth_m")],
                 by=c("Site","Tow"), all.x=TRUE)

# Everything was in October 2022, need to extract the Day of Month:
temp<- strsplit(as.character(tuna_all$Date), split='/')
DayOfMonth<- as.numeric(sapply(temp, '[', 2))
tuna_all$Day<- DayOfMonth

# take only the columns of interest:
latlondate<- tuna_all[,c("Site", "LATITUDE", "LONGITUDE", "Day", "TimeMidTow", "MaxDepth_m")]
# get rid of the duplicate rows:
latlondate<- latlondate[!duplicated(latlondate),]

# Use this to build up the release file:
nrows=length(latlondate$Day)
release2022<- data.frame(polygon=1:nrows, Longitude=latlondate$LONGITUDE,
                         Latitude=latlondate$LATITUDE, Depth=rep(25, nrows), NPart=rep(1000, nrows),
                         year=rep(2022, nrows), month=rep(10, nrows), day=latlondate$Day,
                         seconds = rep(43200, nrows))
                         #seconds=latlondate$TimeMidTow*(24*60*60)-(9*60*60))

# write the release file to a tab-delimited file:
#write.table(release2022, file=here('backtracking','input_pnms2022', 'ReleaseFile_PNMS_Oct2022.txt'), sep='\t', row.names=F, col.names=F)

# Make a key that can match up site and station with release lines:
releasekey<- data.frame(polygon=1:nrows, Site=latlondate$Site,
                        Longitude=latlondate$LONGITUDE,
                        Latitude=latlondate$LATITUDE)
# save as .Rdata:
save(file=here("backtracking","postproc","releaseSiteKey.Rdata"), releasekey)
