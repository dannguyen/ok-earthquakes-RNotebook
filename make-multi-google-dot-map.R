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
quakes <- usgs_data %>% filter(mag >= 3.0, type == 'earthquake', year(time) >= 2006)
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
sw_goog_map <- get_googlemap(center = c(lon = -98.682862, lat = 35.517324),
  size = c(450,450), zoom = 6, scale = 2, maptype = 'terrain',
  style = c(feature = "administrative.province", element = "labels", visibility = "off"))

#############################################
# Visualize
# Note: There has GOT to be an easier way to remove all padding/margin
#  in a multi-row facet grid in which strip.text has a negative vjust.
#  And I wish that whoever knows that way told me about 10 hours ago.
#  Fortunately, the following hack I found on StackOverflow does the job:
# http://stackoverflow.com/questions/15556068/removing-all-the-space-between-two-ggplots-combined-with-grid-arrange


### The map
the_maps <- ggmap(sw_goog_map, extent = 'panel') +
  #### outline Oklahoma
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
               fill = NA, color = "#552200", size = 0.5) +
  #### make it pretty and grid it
  theme_dan_map() +
  theme( strip.text = element_text(vjust = -5.0, size = rel(3.0)),
         panel.margin = unit(0, 'lines')) +
  facet_wrap(~ year, ncol = 5)

### Plot the earthquakes in red
##### 2006 to 2010
p1 <- the_maps + geom_point(data = filter(sw_quakes, year <= 2010),
                  aes(x = longitude, y = latitude), color = "red", shape = 1) +
      theme(plot.margin=unit(c(1, 1, -2.5, 1), "lines"))
##### 2011 to August 2015
p2 <- the_maps +
      geom_point(data = filter(sw_quakes, year >= 2011),
          aes(x = longitude, y = latitude), color = "red", shape = 1) +
      theme(plot.margin=unit(c(-2, 1, 1, 1), "lines"))
grid.arrange(p1, p2, ncol = 1)
# not quite...
