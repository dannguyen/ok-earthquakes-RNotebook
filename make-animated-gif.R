# Note: This script is horseshit. Do not use it in its current state
#       - Dan
options(warn = -1)
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
                   fill = "transparent", color = "#FF6600", size = 0.2)

make_quake_map <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  gggmap +
    geom_point(data = this_data, aes(longitude, latitude),
                 size = 1.5,
                 alpha = 0.25,
                 shape = 8,
                 color = '#990000')  +
    coord_map("albers", lat0 = 38, latl = 42) +
    theme_dan_map() +
    theme(plot.margin=unit(c(-0.5, -1, 0, -1), "cm"))
}


gggbar <- ggplot(cg_quakes, aes(factor(year_month))) +
          geom_histogram(alpha = 0.3, aes(fill = is_OK),
                         binwidth = 1, position = "stack", width = 1.0)

# LOLOL:
make_quake_histogram <- function(yrmth){
  current_date <- ymd(paste(yrmth, '02', sep = '-'))
  this_title <- strftime(current_date, "%Y\n%B")
  # hardcoding this because I'm a weenie
  x_lbl_hjust = ifelse(yrmth > "2015", 1.0, 0.0)
  this_data <- filter(cg_quakes, year_month == yrmth)
  gggbar +
    geom_histogram(data = this_data, alpha = 1.0, color = "#444444", size = 0.1,
      aes(fill = is_OK), binwidth = 1, position = "stack", width = 1.0) +
    scale_y_continuous(breaks=c(100, 200), expand = c(0, 0), limits = c(0, 200)) +
    scale_x_discrete(breaks = c(yrmth), labels = c(this_title)) +
    scale_fill_manual(values = c("#FF6600", "grey")) +
    annotate("text", x = "2005-01", y = 60, size = rel(1.5), hjust = 0,
               label = c("Earthquakes of at least magnitude 3.0\nin the contiguous United States.\n\nChart by Dan Nguyen @dancow\nStanford Computational Journalism")
            ) +
    annotate("text", x = "2013-01", y = 35, size = rel(1.5), hjust = 0,
               label = "Oklahoma's portion of earthquakes\nis colored in orange."
            ) +
    theme(axis.text.x = element_text(color = "black", hjust = x_lbl_hjust ,
              size = rel(0.4)),
          legend.position="none",
          axis.line = element_line(color = "#666666", size = 0.1),
          axis.line.x = element_line(color = "#666666", size = 0.1),
          axis.line.y = element_blank(),
          axis.text.y = element_text(size = rel(0.5), hjust = 0.0, color = "#666666"),
          panel.grid.major = element_line(size = 0.2, colour = "#555555",
            linetype = "dotted")
      )
}


##############################################################
# The image making function
make_clips <- function(items){
  # I think this is how you do a loop in R(???)
  lapply(items, function(ym) {
    comp_name = paste("/tmp/movie-quakes/composite-", ym, '.png', sep = "")
    m_name <- paste("/tmp/movie-quakes/map-", ym, '.png', sep = "")
    ggsave(m_name, height=3, width=5, plot = make_quake_map(ym), device = 'png',
       bg="transparent")
    b_name <- paste("/tmp/movie-quakes/histogram-", ym, '.png', sep = "")
    ggsave(b_name, height=2, width=5, plot = make_quake_histogram(ym),
      device = 'png', bg="transparent")
    print(as.character(ym))
    # Here's where I gave up on R. Good ol Bash and ImageMagick saves the day
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
print("Making animated GIF!")
system("convert -delay 15 /tmp/movie-quakes/composite-*.png /tmp/movie-quakes/movie-quakes-OK.gif")
system("convert /tmp/movie-quakes/movie-quakes-OK.gif -resize 60% /tmp/movie-quakes/movie-quakes-OK-med.gif")
system("convert /tmp/movie-quakes/movie-quakes-OK.gif -resize 30% /tmp/movie-quakes/movie-quakes-OK-small.gif")

print("Making optimized version!")
system("gifsicle -O3 --colors 64 /tmp/movie-quakes/movie-quakes-OK.gif > /tmp/movie-quakes/optimized-movie-quakes-OK.gif")
system("gifsicle -O3 --colors 64 --resize-width 1000 /tmp/movie-quakes/movie-quakes-OK.gif > /tmp/movie-quakes/optimized-movie-quakes-OK-med.gif")
system("gifsicle -O3 --colors 64 --resize-width 600 /tmp/movie-quakes/movie-quakes-OK.gif > /tmp/movie-quakes/optimized-movie-quakes-OK-small.gif")


# I give up...avconv does not like image piping
print("Make a movie")
system('
  x=1;
  for i in /tmp/movie-quakes/composite*.png;
  do counter=$(printf %03d $x);
  ln -s $i /tmp/movie-quakes/_tmpimage-$counter.png;
  x=$(($x+1));
  done')
system("avconv -y -r 5 -i /tmp/movie-quakes/_tmpimage-%03d.png /tmp/movie-quakes/movie-quakes-OK.mp4")

print("all done")

30 # I put this here because the script crashes on print for some reason. Whatever
