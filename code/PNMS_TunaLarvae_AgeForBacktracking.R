################################################################################
### Code to make age matrices for plotting backtracking data in Matlab
################################################################################
library(here)

load(here("backtracking","postproc", "releaseSiteKey.Rdata"))
load(here("results", "PNMS_LengthAge.Rdata"))

# Separate "Site" into "Site" and "Station" in releasekey:
sampleid<- strsplit(as.character(releasekey$Site), split='_')
releasekey$Site<- sapply(sampleid, '[', 1)
releasekey$Station<- sapply(sampleid, '[', 2)

## Section for re-calculating  estimated ages ----------------------------------
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

## Write a file for each taxon -------------------------------------------------
# that contains ONLY the release line, the estimated age, and the station temperature

# Thunnus albacares:
I<- which(length_data$Species=="Thunnus albacares")
ageThunnus<- length_data[I,c("Site", "Station", "Age", "Temperature_depth")]
ageThunnus<- merge(ageThunnus, releasekey)
ageThunnus<- ageThunnus[, c("polygon", "Age", "Temperature_depth")]
write.table(ageThunnus,
            file=here("backtracking", "postproc", "PNMS2022_YellowfinEstAges.csv"),
            sep=',', row.names = FALSE, col.names = FALSE)

# Thunnus obesus:
I<- which(length_data$Species=="Thunnus obesus")
ageThunnus<- length_data[I,c("Site", "Station", "Age", "Temperature_depth")]
ageThunnus<- merge(ageThunnus, releasekey)
ageThunnus<- ageThunnus[, c("polygon", "Age", "Temperature_depth")]
write.table(ageThunnus,
            file=here("backtracking", "postproc", "PNMS2022_BigeyeEstAges.csv"),
            sep=',', row.names = FALSE, col.names = FALSE)

# Katsuwonus:
ageKatsuwonus<- length_data[length_data$Species=="Katsuwonus pelamis",c("Site", "Station", "Age", "Temperature_depth")]
ageKatsuwonus<- merge(ageKatsuwonus, releasekey)
ageKatsuwonus<- ageKatsuwonus[, c("polygon", "Age", "Temperature_depth")]
write.table(ageKatsuwonus,
            file=here("backtracking", "postproc", "PNMS2022_KatsuwonusEstAges.csv"),
            sep=',', row.names = FALSE, col.names = FALSE)

# Auxis:
ageAuxis<- length_data[length_data$Species=="Auxis thazard",c("Site", "Station", "Age", "Temperature_depth")]
ageAuxis<- merge(ageAuxis, releasekey)
ageAuxis<- ageAuxis[, c("polygon", "Age", "Temperature_depth")]
write.table(ageAuxis,
            file=here("backtracking", "postproc", "PNMS2022_AuxisEstAges.csv"),
            sep=',', row.names = FALSE, col.names = FALSE)



