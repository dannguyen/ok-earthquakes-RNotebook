library(ggplot2)
library(grid)
library(dplyr)
library(lubridate)
library(rgdal)
library(gridExtra)
library(ggmap)
# note: ggmap2.5.2.9000 must be loaded to allow the use of non-square Google Maps:
# https://github.com/dkahle/ggmap/issues/17
# If not on cran, install the devtools package and install via Github:
# devtools::install_github("dkahle/ggmap")


# load my themes:
source("./myslimthemes.R")

#############################################
# Download US Census boundaries
fname <- "./data/cb_2014_us_state_20m.zip"
if (!file.exists(fname)){
  url <- "http://www2.census.gov/geo/tiger/GENZ2014/shp/cb_2014_us_state_20m.zip"
  print(paste("Downloading: ", url))
  download.file(url, fname)
}
unzip(fname, exdir = "./data/shp")

#############################################
# Read the map data
us_map <- readOGR("./data/shp/cb_2014_us_state_20m.shp", "cb_2014_us_state_20m")
# Include only Oklahoma and bordering states
sw_map <- us_map[us_map$STUSPS %in% c('OK', 'AR', 'CO', 'KS', 'MO', 'NM', 'TX'),]
# For convenience, just the OK boundaries
ok_map <- sw_map[sw_map$STUSPS == 'OK',]

#############################################
# Download and read the 1995-8/2015 USGS data
fn <- './data/usgs-quakes-dump.csv'
zname <- paste(fn, 'zip', sep = '.')
if (!file.exists(zname) || file.size(zname) < 2048){
  url <- paste("https://github.com/dannguyen/ok-earthquakes-RNotebook",
    "raw/master/data", zname, sep = '/')
  print(paste("Downloading: ", url))
  # note: if you have problems downloading from https,
  #you might need to include RCurl
  download.file(url, zname, method = "libcurl")
}
unzip(zname, exdir="data")

#############################################
# Read and filter the data for just M3.0+ earthquakes since 2006
usgs_data <- read.csv(fn, stringsAsFactors = FALSE)
quakes <- usgs_data %>% filter(mag >= 3.0, type == 'earthquake', year(time) >= 2004)
# Filter the data for just quakes in the southwestern states
x_quakes <- SpatialPointsDataFrame(data = quakes,
                coords = quakes[,c("longitude", "latitude")])
x_quakes@proj4string <- sw_map@proj4string
xdf <- over(x_quakes, sw_map[, 'STUSPS'])
sw_quakes <- cbind(x_quakes, xdf) %>% filter(!is.na(STUSPS))
# add a convenience column for Oklahoma and a year column:
sw_quakes <- mutate(sw_quakes, is_OK = STUSPS == 'OK', year = year(time))

#############################################
# Get a Google Map
sw_goog_map <- get_googlemap(center = c(lon = -99.007, lat = 35.38905),  size = c(450,250), zoom = 6,
                             scale = 2, maptype = 'terrain',
  style = c(feature = "administrative.province", element = "labels", visibility = "off"))


p <- ggmap(sw_goog_map, extent = 'panel') +
  #### outline Oklahoma
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
               fill = NA, color = "#5d8048", size = 0.3) +
  geom_point(data = filter(sw_quakes),
                            aes(x = longitude, y = latitude),
                            size = 1.2, alpha = 0.8, color = "red", shape = 1) +
  #### make it pretty and grid it
  theme_dan_map() +
  labs(x=NULL, y=NULL) +
  theme( strip.text = element_text(hjust = 0.11, vjust = -4.2, size = rel(1.1)),
         panel.margin.x = unit(0, 'lines'),
         panel.margin.y = unit(-1.2, 'lines'),
        plot.margin = unit(c(0, 0, 0, 0), 'in')) +
  facet_wrap(~ year, ncol = 4)


ggsave(filename = "./images/multi-year-OK-google-map.jpg",
  plot = p,
  scale = 1, width = 8, height = 3,
  units = "in", dpi = 300, limitsize = F)
