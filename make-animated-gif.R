library(ggplot2)
require(grid)
library(dplyr)
library(lubridate)
library(rgdal)
library(maptools)
require(gridExtra)

setwd("~/Dropbox/rprojs/ok-earthquakes-Rnotebook/")
source("./myslimthemes.R")
theme_set(theme_dan())

# download map data
fname <- "./data/cb_2014_us_state_20m.zip"
if (!file.exists(fname)){
  url <- "http://www2.census.gov/geo/tiger/GENZ2014/shp/cb_2014_us_state_20m.zip"
  print(paste("Downloading: ", url))
  download.file(url, fname)
}
unzip(fname, exdir = "./data/shp")

# load Map data
us_map <- readOGR("./data/shp/cb_2014_us_state_20m.shp", "cb_2014_us_state_20m")
states_map <- us_map[!us_map$STUSPS %in%
                        c('AS', 'DC', 'GU', 'MP', 'PR', 'VI'),]
# For mapping purposes, we'll make a contiguous-states only
cg_map <- states_map[!states_map$STUSPS %in% c('AK', 'HI'), ]
ok_map <- cg_map[cg_map$STUSPS == 'OK',]

# Quakes data
fn <- './data/usgs-quakes-dump.csv'
zname <- paste(fn, 'zip', sep = '.')
if (!file.exists(zname) || file.size(zname) < 2048){
  url <- paste("https://github.com/dannguyen/ok-earthquakes-RNotebook",
    "raw/master/data", zname, sep = '/')
  print(paste("Downloading: ", url))
  # note: if you have problems downloading from https, you might need to include
  # RCurl
  download.file(url, zname, method = "libcurl")
}
unzip(zname, exdir="data")
# read the data into a dataframe
usgs_data <- read.csv(fn, stringsAsFactors = FALSE)

quakes <- usgs_data %>% filter(year(time) >= 2005, mag >= 3.0) %>%
  filter(type == 'earthquake') %>%
  mutate(year_month = strftime(time, '%Y-%m'))

sp_quakes <- SpatialPointsDataFrame(data = quakes,
                          coords = quakes[,c("longitude", "latitude")])
sp_quakes@proj4string <- states_map@proj4string

# subset for earthquakes in the contiguous U.S.
xdf <- over(sp_quakes, cg_map[, 'STUSPS'])
cg_quakes <- cbind(sp_quakes, xdf) %>% filter(!is.na(STUSPS))
cg_quakes <- mutate(cg_quakes, is_OK = ifelse(STUSPS == 'OK', 'OK', 'Other'))

# Make the map -------------------------


make_quake_map <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  ggplot() +
  geom_polygon(data = cg_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "orange", size = 0.5) +

  geom_point(data = this_data, aes(longitude, latitude),
               size = 1.5,
               alpha = 0.5,
               shape = 1,
               color = 'firebrick')  +
  coord_map("albers", lat0 = 38, latl = 42) +
  theme_dan_map()
}


make_quake_histogram <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  ggplot(cg_quakes, aes(factor(year_month))) +
    geom_histogram(alpha = 0.3, aes(fill = is_OK),
       binwidth = 1, position = "stack", width = 1.0) +
    geom_histogram(data = this_data, alpha = 1.0,
      aes(fill = is_OK), binwidth = 1, position = "stack", width = 1.0) +
    scale_fill_manual(values = c("orange", "grey")) +
    theme(axis.text.x = element_blank())
}


make_it_so <- function(yrmth){
  mymap <- make_quake_map(yrmth) +
      theme(plot.margin=unit(c(-2, -3, -2, -3), "cm"))
  mybar <- make_quake_histogram(yrmth)

  print(grid.arrange(mymap, mybar, ncol = 2))
}



library(animation)
yrmths = unique(cg_quakes$year_month)
make_movie <- function(items){
  lapply(items, function(i) {
    make_it_so(i)
  }
)}
saveGIF(make_movie(yrmths), interval = .1, movie.name="/tmp/quakes.gif")
