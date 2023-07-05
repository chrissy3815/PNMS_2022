################################################################################
### Code for analyzing tuna larvae from PNMS samples
### Samples collected Oct 2022
### Analysis code written July 2023
################################################################################

# load packages
library(openxlsx)
library(here)

# read in the data tables:
photo_data<- read.csv(here("data", "PAL22_Tuna photo data.csv"))
photo_calibration<- read.xlsx(here("data", "PNMS_Calibration.xlsx"))
length_data<- read.table(here("data","LengthResults_July2023.txt"), header=TRUE)

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

