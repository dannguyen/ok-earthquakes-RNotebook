# Note: This script is a massive hack and requires a lot of non-R dependencies
#   in order to run out of the box. It uses imagemagick to glue all the charts
#   together and gifsicle to optimize the GIF.
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
print("Reading 20 years worth of USGS earthquake data...")
usgs_data <- read.csv(fn, stringsAsFactors = FALSE)


##############################################################
# Filter quake data
print("Filtering for 2005 to 2015 data...")
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
my_map <- ggplot() +
  geom_polygon(data = cg_map, aes(x = long, y = lat, group = group),
                   fill = "transparent", color = "#444444", size = 0.1) +
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
                   fill = "transparent", color = "#FF6600", size = 0.2)

make_quake_map <- function(yrmth){
  this_data <- filter(cg_quakes, year_month == yrmth)
  my_map +
    geom_point(data = this_data, aes(longitude, latitude),
                 size = 1.3,
                 alpha = 0.75,
                 shape = 1,
                 color = '#BB2222')  +
    coord_map("albers", lat0 = 38, latl = 42) +
    theme_dan_map() +
    theme(plot.margin=unit(c(-0.5, -1, 0, -1), "cm"))
}


my_hist <- ggplot(cg_quakes, aes(factor(year_month))) +
          geom_histogram(alpha = 0.3, aes(fill = is_OK),
                         binwidth = 1, position = "stack", width = 1.0)

# LOLOL:
make_quake_histogram <- function(yrmth){
  current_date <- ymd(paste(yrmth, '02', sep = '-'))
  this_title <- strftime(current_date, "  %Y  \n  %B  ")
  # hardcoding this because I'm a weenie
  x_lbl_hjust = ifelse(yrmth > "2015", 1.0, 0.0)
  this_data <- filter(cg_quakes, year_month == yrmth)
  my_hist +
    geom_histogram(data = this_data, alpha = 1.0, color = "#444444", size = 0.1,
      aes(fill = is_OK), binwidth = 1, position = "stack", width = 1.0) +
    scale_y_continuous(breaks=c(100, 200), expand = c(0, 0), limits = c(0, 200)) +
    scale_x_discrete(breaks = c(yrmth), labels = c(this_title)) +
    scale_fill_manual(values = c("#FF6600", "grey")) +
    # annotate year marks
    annotate("text", x = "2005-01", y = 6, size = rel(1.5), hjust = 0.0,
               label = "2005", fontface = 'bold', family = "Gill Sans MT") +
    annotate("text", x = "2010-01", y = 6, size = rel(1.5), hjust = 0.0,
               label = "2010", fontface = 'bold', family = "Gill Sans MT") +
    annotate("text", x = "2015-01", y = 6, size = rel(1.5), hjust = 0.0,
               label = "2015", fontface = 'bold', family = "Gill Sans MT") +
    annotate("text", x = yrmth, y = 25, size = rel(1.3), hjust = x_lbl_hjust,
               label = this_title, lineheight = 0.8, family = "Gill Sans MT") +
    # annotate chart text
    annotate("text", x = "2005-01", y = 100, size = rel(1.5), hjust = 0, family = "Gill Sans MT",
               label = c("Earthquakes of at least magnitude 3.0\nin the contiguous United States.\n\nData from the U.S. Geological Survey.\nChart by Dan Nguyen @dancow\nStanford Computational Journalism")
            ) +
    annotate("text", x = "2013-03", y = 50, size = rel(1.5), hjust = 0, family = "Gill Sans MT",
               label = "Oklahoma's portion of earthquakes\nis colored in orange."
            ) +


    theme( legend.position="none",
          axis.line = element_line(color = "#666666", size = 0.1),
          axis.line.x = element_line(color = "#666666", size = 0.1),
          axis.line.y = element_blank(),
          axis.text.x = element_blank(),
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
    ggsave(m_name, height=3, width=5, plot = make_quake_map(ym),
       bg="transparent")
    b_name <- paste("/tmp/movie-quakes/histogram-", ym, '.png', sep = "")
    ggsave(b_name, height=2, width=5, plot = make_quake_histogram(ym),
      bg="transparent")
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
system("gifsicle -O3 --colors 64 /tmp/movie-quakes/movie-quakes-OK.gif > ./images/optimized-movie-quakes-OK.gif")
system("gifsicle -O3 --colors 64 --resize-width 1000 /tmp/movie-quakes/movie-quakes-OK.gif > ./images/optimized-movie-quakes-OK-med.gif")
system("gifsicle -O3 --colors 64 --resize-width 600 /tmp/movie-quakes/movie-quakes-OK.gif > ./images/optimized-movie-quakes-OK-small.gif")


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
