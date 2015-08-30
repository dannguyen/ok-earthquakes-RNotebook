
options(warn=-1)

library(ggplot2)
require(grid)
library(dplyr)
library(lubridate)
library(rgdal)

setwd("~/Dropbox/rprojs/ok-earthquakes-Rnotebook/")
source("./myslimthemes.R")
theme_set(theme_dan())

##############################################################
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

##############################################################
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
print("Reading 20 years worth of USGS earthquake data")
usgs_data <- read.csv(fn, stringsAsFactors = FALSE)


##############################################################
# Filter quake data
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

##############################################################
# Make the map -------------------------
gggmap <- ggplot() +
  geom_polygon(data = cg_map, aes(x = long, y = lat, group = group),
                   fill = "transparent", color = "#444444", size = 0.1) +
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
                   fill = "transparent", color = "#FF6600", size = 0.5)

make_quake_map <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  # make a title
  current_date <- ymd(paste(yrmth, '02', sep = '-'))
  this_title <- strftime(current_date, "%B %Y")
  # make decay data
  last_mth <- strftime(current_date %m-% months(1), '%Y-%m')
  last_mth_data <- filter(cg_quakes, year_month == last_mth)
  gggmap +
    # add last month decay
    geom_point(data = last_mth_data, aes(longitude, latitude),
                 size = 1.3,
                 alpha = 0.2,
                 color = '#CC7777')  +
    # add this month
    geom_point(data = this_data, aes(longitude, latitude),
                 size = 1.5,
                 alpha = 0.3,
                 shape = 8,
                 color = '#990000')  +


    coord_map("albers", lat0 = 38, latl = 42) +
    theme_dan_map() +
    theme(
      plot.margin=unit(c(-0.5, -1, 0, -1), "cm"),
      axis.title = element_text(color = 'black', size = rel(0.8)),
      axis.title.y = element_blank()) +
      labs(x = this_title)
}


gggbar <- ggplot(cg_quakes, aes(factor(year_month))) +
            geom_histogram(alpha = 0.3, aes(fill = is_OK),
            binwidth = 1, position = "stack", width = 1.0)

make_quake_histogram <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  gggbar +
    geom_histogram(data = this_data, alpha = 1.0, color = "#444444", size = 0.1,
      aes(fill = is_OK), binwidth = 1, position = "stack", width = 1.0) +

    scale_y_continuous(breaks=c(0, 100)) +
    scale_fill_manual(values = c("#FF6600", "grey")) +
    theme(axis.text.x = element_blank(), legend.position="none",
      axis.text.y = element_text(size = rel(0.5), hjust = 0.0, color = "#666666"),
      panel.grid.major = element_line(size = 0.2, colour = "#777777",
        linetype = "dotted")
      )
}


##############################################################
# The image making function
make_clips <- function(items){
  lapply(items, function(ym) {
    comp_name = paste("/tmp/movie-quakes/composite-", ym, '.png', sep = "")
    m_name <- paste("/tmp/movie-quakes/map-", ym, '.png', sep = "")
    ggsave(m_name, height=3, width=5, plot = make_quake_map(ym), device = 'png',
       bg="transparent")
    b_name <- paste("/tmp/movie-quakes/histogram-", ym, '.png', sep = "")
    ggsave(b_name, height=2, width=5, plot = make_quake_histogram(ym),
      device = 'png', bg="transparent")
    print(as.character(ym))

    system(paste("convert -size 1500x1000 xc:white", comp_name))
    system(paste("composite -geometry +0+400", b_name, comp_name, comp_name))
    system(paste("composite -geometry +0+0", m_name, comp_name, comp_name))
  }
)}

#######################################
# Let's go
print("Making stills!")
yrmths = unique(cg_quakes$year_month)
make_clips(yrmths)
print("Making it animated!")
system("convert -delay 15 /tmp/movie-quakes/composite-*.png /tmp/movie-quakes/movie-quakes-OK.gif")
print("Making a small version")
system("convert /tmp/movie-quakes/movie-quakes-OK.gif -resize 50% /tmp/movie-quakes/movie-quakes-OK-small.gif")
print("all done")

30
