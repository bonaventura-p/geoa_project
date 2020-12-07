#Niger CAD maps
install.packages("dplyr")
library(dplyr)

#Data preparation
data<-read.csv("C:/Users/jofre/Downloads/20200324 Cartographie - Liste des acteurs - L2-L3-l4 Oscar Version - Sheet3 (5).csv", header=T, encoding="UTF-8", stringsAsFactors=T)

for (i in levels(data$Sector)){ 
  assign(paste0("data_", i ),data.frame(table(data$Region[data$Sector==i])))
  }

#Mapping
install.packages("sf")
library(sf)
library(rgdal)
nigermap<-st_read("C:/Users/jofre/Google Drive/nigermap/files/adm01.shp")

#Basic map by regions

#Turning the map into the sf package format 
map=st_as_sf(nigermap, plot = FALSE, fill = TRUE)
#Binding centroids of regions in the sf data frame in order to put the lables
map <- cbind(map, st_coordinates(st_centroid(map)))
#Merging (by cbidning) our substantial data into the sf data frame map
map <- map[order(map$adm_01),]
map <- cbind(map, data_Commerce$Freq)
map <- rename(map,  Commerce=data_Commerce.Freq)
map <- cbind(map, data_Construction$Freq)
map <- rename(map,  Construction=data_Construction.Freq)
map <- cbind(map, data_Agriculture$Freq)
map <- rename(map,  Agriculture=data_Agriculture.Freq)
map <- cbind(map, data_Télécommunications$Freq)
map <- rename(map,  Télécommunications=data_Télécommunications.Freq)
map <- cbind(map, data_Banques$Freq)
map <- rename(map,  Banques=data_Banques.Freq)

sectors=c("Agri", "Constr", "Com", "Banq", "Tel")

map=read.csv()

Com<-read.csv("C:/Users/jofre/Downloads/Untitled spreadsheetCom.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
Agri<-read.csv("C:/Users/jofre/Downloads/Untitled spreadsheetAgri.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
Constr<-read.csv("C:/Users/jofre/Downloads/Untitled spreadsheetConstr.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
Banq<-read.csv("C:/Users/jofre/Downloads/Untitled spreadsheetBanq.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
Tel<-read.csv("C:/Users/jofre/Downloads/Untitled spreadsheetTel.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
map <- cbind(map, Com$Freq)
map <- cbind(map, Agri$Freq)
map <- cbind(map, Constr$Freq)
map <- cbind(map, Banq$Freq)
map <- cbind(map, Tel$Freq)

# Basic map
ggplot() + 
  geom_sf(data = map, size = .5, color = "black") + 
  geom_text(data = map, aes(X, Y, label = map$adm_01), size = 3) +
  ggtitle("Nigermap")+
  scale_fill_brewer("Nombre d'entités par région") + # fill with brewer colors
  theme(line = element_blank(),  # remove the background, tickmarks, etc
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())

# Substantial maps
# Creating deviation for the region label
map$nudge_x=-0.5
map$nudge_xx=0.5

a=ggplot(data = map) +
  ggtitle("Télécommunications")+
  geom_sf(data = map, aes(fill = Tel$Freq)) +
  geom_text(data = map, aes(X, Y, label = Tel$Freq), size = 3,fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_b(trans = "sqrt", alpha = .3)+
  theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
a=a+labs(fill = "Nombre d'entités")
a
b<-ggplot(data = map) +
  ggtitle("Construction")+
  geom_sf(data = map, aes(fill = Constr$Freq)) +
  geom_text(data = map, aes(X, Y, label = Constr$Freq), size = 3,fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_b(trans = "sqrt", alpha = .3)+
  theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
b=b+labs(fill = "Nombre d'entités")

c<-ggplot(data = map) +
  ggtitle("Agriculture")+
  geom_sf(data = map, aes(fill = Agri$Freq)) +
  geom_text(data = map, aes(X, Y, label = Agri$Freq), size = 3,fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_b(trans = "sqrt", alpha = .3)+
  theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
c=c+labs(fill = "Nombre d'entités")

d<-ggplot(data = map) +
  ggtitle("Banques")+
  geom_sf(data = map, aes(fill = Banq$Freq)) +
  geom_text(data = map, aes(X, Y, label = Banq$Freq), size = 3,fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_b(trans = "sqrt", alpha = .3)+
  theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
d=d+labs(fill = "Nombre d'entités")

e<-ggplot(data = map) +
  ggtitle("Commerce")+
    geom_sf(data = map, aes(fill = Com$Freq)) +
  geom_text(data = map, aes(X, Y, label = Com$Freq), size = 3, fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_b(trans = "sqrt", alpha = .3)+
  theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
e=e+labs(fill = "Nombre d'entités")

ggarrange(
  a,b,c,d,e,
  common.legend = F, legend = "bottom"
)

a
b
c
d
e

# General map

genmap<-read.csv("C:/Users/jofre/Downloads/general_cad_map.csv", header=T, encoding="UTF-8", stringsAsFactors=T)
genmap <- genmap[order(genmap$Region),]
map <- cbind(map, genmap$Freq)
map <- rename(map, General=genmap.Freq)

if (!require("RColorBrewer")) {
  install.packages("RColorBrewer")
  library(RColorBrewer)
}

f<-ggplot(data = map) +
  ggtitle("Répartition des acteurs par région")+
  geom_sf(data = map, aes(fill = General)) +
  geom_text(data = map, aes(X, Y, label = General), size = 3, fontface = "bold", nudge_x = map$nudge_xx) +
  geom_text(data = map, aes(X, Y, label = adm_01), size = 3, fontface = "bold", nudge_x = map$nudge_x) +
  scale_fill_viridis_c(trans = "sqrt", alpha = .3)+
    theme(line = element_blank(), 
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.background = element_blank())
f=f+labs(fill = "Nombre d'entités")
f
