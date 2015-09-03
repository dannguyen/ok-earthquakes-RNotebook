Part 2: Basic R Concepts
========================

Loading the libraries and themes
--------------------------------

``` r
library(ggplot2)
library(scales)
library(grid)
library(dplyr)
library(lubridate)
library(rgdal)
```

-   [ggplot2](http://ggplot2.org/) is *the* visualization framework. Made by Hadley Wickham.
-   [dplyr](https://cran.rstudio.com/web/packages/dplyr/vignettes/introduction.html), also made by Hadley Wickham, is a library for manipulating dataframes and includes transformations such as `mutate()` and `filter()` as well as aggregation functions. It also has [nice piping](http://seananderson.ca/2014/09/13/dplyr-intro.html), which warms the Unix programmer inside me.
-   [lubridate](https://github.com/hadley/lubridate) - Another Wickham creation that greatly eases working with time values, which will be helpful when generating time-series and time-based filters. Think of it as [moment.js for R](http://momentjs.com/).
-   [scales](https://github.com/hadley/scales) - Yet another Wickham library, this one is focused on properly scaling axes, among other things, which is particularly helpful for us in making time-series.
-   [grid](https://stat.ethz.ch/R-manual/R-devel/library/grid/html/grid-package.html) - contains some functionality that ggplot2 uses for chart styling, particularly the [unit()](https://stat.ethz.ch/R-manual/R-devel/library/grid/html/unit.html) function.
-   [rgdal](https://cran.r-project.org/web/packages/rgdal/index.html) - bindings for geospatial operations, including map projection and the reading of map shapefiles. Can be a bear to install due to a variety of dependencies. If you're on OS X, I recommend [installing Homebrew](http://brew.sh/) and running `brew install gdal` before installing the rgdal package via R.

``` r
source("./myslimthemes.R")
theme_set(theme_dan())
```

Downloading the data
--------------------

There are two data files we need:

-   **[A feed of earthquake reports in CSV format from the U.S. Geological Survey](http://earthquake.usgs.gov/earthquakes/feed/v1.0/csv.php).** For this section, we'll start by using the ["Past 30 Days - All Earthquakes"](http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv) feed, which can be downloaded at this URL:

    <http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv>

-   **[Cartographic boundary shapefiles for U.S. state boundaries, via the U.S. Census](https://www.census.gov/geo/maps-data/data/tiger-cart-boundary.html)**. The listing of state boundaries can be [found here](https://www.census.gov/geo/maps-data/data/cbf/cbf_state.html). There are several levels of detail; the resolution of `1:20,000,000` is good enough for our purposes:

    <http://www2.census.gov/geo/tiger/GENZ2014/shp/cb_2014_us_state_20m.zip>

If you're following along many years from now and the above links no longer work, the [Github repo for this walkthrough](https://github.com/dannguyen/ok-earthquakes-RNotebook) contains copies of the raw files for you to practice on. You can either just clone this repo to get the files. Or download them here (these URLs are subject to the whims of Github's framework and may change down the road):

-   <https://raw.githubusercontent.com/dannguyen/ok-earthquakes-RNotebook/master/data/all_month.csv>
-   <https://raw.githubusercontent.com/dannguyen/ok-earthquakes-RNotebook/master/data/cb_2014_us_state_20m.zip>

First we create a data directory to store our files:

``` r
dir.create('./data')
```

### Download earthquake data into a data frame

Because the data files can get big, I've included an `if` statement so that if a file exists at `./data/all_month.csv`, the `download` command won't attempt to re-download the file.

``` r
url <- "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv"
fname <- "./data/all_month.csv"
if (!file.exists(fname)){
  print(paste("Downloading: ", url))
  download.file(url, fname)
}
```

Alternatively, to download a specific interval of data, such as just the earthquakes for **August 2015**, use [the USGS Archives endpoint](http://earthquake.usgs.gov/earthquakes/search/):

``` r
base_url <- 'http://earthquake.usgs.gov/fdsnws/event/1/query.csv?'
starttimeparam <- 'starttime=2015-08-01 00:00:00'
endtime_param <- 'endtime=2015-08-31 23:59:59'
orderby_param <- 'orderby=time-asc'
url <- paste(base_url, starttimeparam, endtime_param, orderby_param, sep = "&")
print(paste("Downloading: ", url))
fname = 'data/2015-08.csv'
download.file(url, fname)
```

The standard **read.csv()** function can be used to convert the CSV file into a data frame, which I store into a variable named `usgs_data`:

``` r
usgs_data <- read.csv(fname, stringsAsFactors = FALSE)
```

#### Convert the `time` column to a Date-type object

The `time` column of `usgs_data` contains timestamps of the events:

``` r
head(usgs_data$time)
```

    ## [1] "2015-08-01T00:07:41.000Z" "2015-08-01T00:13:14.660Z"
    ## [3] "2015-08-01T00:23:01.590Z" "2015-08-01T00:30:14.000Z"
    ## [5] "2015-08-01T00:30:50.820Z" "2015-08-01T00:43:56.220Z"

However, these values are *strings*; to work with them as measurements of *time*, e.g. in creating a time-series chart, we convert them to time objects (more specifically, objects of class **POSIXct**). The **lubridate** package provides the useful **ymd\_hms()** function for fairly robust parsing of strings.

The standard way to transform a data frame column looks like this:

``` r
usgs_data$time <- ymd_hms(usgs_data$time)
```

However, I'll often use the **mutate()** function from the **dplyr** package:

``` r
usgs_data <- mutate(usgs_data, time =  ymd_hms(time))
```

### Download and read the map data

``` r
url <- "http://www2.census.gov/geo/tiger/GENZ2014/shp/cb_2014_us_state_20m.zip"
fname <- "./data/cb_2014_us_state_20m.zip"
if (!file.exists(fname)){
  print(paste("Downloading: ", url))
  download.file(url, fname)
}
unzip(fname, exdir = "./data/shp")
```

Inside the `data/` directory should be a subdirectory named `shp/` with a variety of data files. Using the **rgdal** library, we use the `readOGR()` command to read the shape file, convert it to a **SpatialPolygonsDataFrame**-type object, and assign it to the variable `us_map`:

``` r
us_map <- readOGR("./data/shp/cb_2014_us_state_20m.shp", "cb_2014_us_state_20m")
```

Going forward, we can work knowing that `usgs_data` and `us_map` contain data frames for the earthquakes and the U.S. state boundaries, respectively.

Examining the earthquake data
-----------------------------

Let's count how many earthquake records there are in a month's worth of USGS earthquake data:

``` r
nrow(usgs_data)
```

    ## [1] 8826

An initial attempt at visualization might use a scatterplot, in which the each earthquake is plotted by its time and magnitude on the x- and y-axis, respectively:

``` r
ggplot(usgs_data, aes(x = time, y = mag)) +
  geom_point() +
  scale_x_datetime() +
  ggtitle("Worldwide seismic events for August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/overplotted_earthquakes-1.png)

With so many earthquake events, we have a problem of **overplotting**: Events of similar magnitude that occur close to each other chronologically will overlap as dots. One way to fix this is to change the shape of the dots and increase their transparency:

``` r
ggplot(usgs_data, aes(x = time, y = mag)) +
  geom_point(alpha = 0.2) +
  scale_x_datetime() +
  ggtitle("Worldwide seismic events for August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/overplotted_earthquakes_with_alpha-1.png)

That's a little better. But there are just too many points for us to visually process. For example, we can tell that there are more earthquakes in the magnitude range of 0 to 2, but there's too much visual noise to quantify the difference.

So let's use a **histogram** to group the earthquakes by nearest integer:

``` r
# I use a factor to make neater-looking bars
ggplot(usgs_data, aes(x = factor(round(mag)))) +
  geom_histogram(binwidth = 1) +
  scale_y_continuous(expand = c(0, 0)) + # to remove margins from bottom of plot
  ggtitle("Worldwide earthquakes by magnitude, rounded to nearest integer")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/histogram_quakes_rounded_integer-1.png)

The USGS data feed contains more than just earthquakes, though. So we use dplyr's **group\_by()** function on the `type` column and then **summarise()** the record counts:

``` r
usgs_data %>% group_by(type) %>% summarise(count = n())
```

    ## Source: local data frame [3 x 2]
    ## 
    ##           type count
    ## 1   earthquake  8675
    ## 2    explosion    43
    ## 3 quarry blast   108

For this particular journalstic endeavour, we don't care about explosions and quarry blasts. We also only care about events of a reasonable magnitude – [remember that magnitudes under 3.0 are often not even noticed by the average person](http://earthquake.usgs.gov/learn/topics/mag_vs_int.php). Likewise, most of the stories about [Oklahoma's earthquakes](https://news.yahoo.com/more-bigger-drilling-linked-earthquakes-rattle-oklahoma-073805543.html) focus on earthquakes of magnitude of at least **3.0**, so let's filter `usgs_data` appropriately and store the result in a variable named `quakes`:

There are several ways to create a subset of a data frame:

-   Using bracket notation:

        quakes <- usgs_data[usgs_data$mag >= 3.0 & usgs_data$type == 'earthquake',]

-   Using `subset()`:

        quakes <- subset(usgs_data, usgs_data$mag >= 3.0 & usgs_data$type == 'earthquake')

-   And my preferred convention: using dplyr's `filter()`:

``` r
quakes <- usgs_data %>% filter(mag >= 3.0, type == 'earthquake')
```

The `quakes` dataframe is now about a tenth the size of the data we original downloaded, which will work just fine for our purposes:

``` r
nrow(quakes)
```

    ## [1] 976

### Plotting the earthquake data without a map

It's worth remembering that a geographical map can be thought of a [plain ol' scatter plot](http://docs.ggplot2.org/0.9.3/geom_point.html). In this case, each dot is plotted using the **longitude** and **latitude** values, which serve as the **x** and **y** coordinates, respectively:

``` r
ggplot(quakes, aes(x = longitude, y = latitude)) + geom_point()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/quake_points_no_map-1.png)

Even without the world map boundaries, we can see in the locations of the earthquakes a rough outline of the world's fault lines:

![Digital Tectonic Activity Map of the Earth, via NASA](./images/Plate_tectonics_map.gif)

Even with just ~1,000 points – and, in the next chapter, **20,000+** points, we again run into a problem of [**overplotting**](http://www.cookbook-r.com/Graphs/Scatterplots_(ggplot2)/#handling-overplotting), so I'll increase the size and transparency of each point and change the point shape. And just to add some variety, I'll change the [color](http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf) of the points from black to `firebrick`:

We can apply these styles in the `geom_point()` call:

``` r
ggplot(quakes, aes(x = longitude, y = latitude)) +
  geom_point(size = 3,
             alpha = 0.2,
             shape = 4,
             color = 'firebrick')
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/quake_points_no_map_alpha_fix-1.png)

#### Varying the size by magnitude

Obviously, some earthquakes are more momentous than others. An easy way to show this would be to vary the *size* of the point by `mag`:

``` r
ggplot(quakes, aes(x = longitude, y = latitude)) +
  geom_point(aes(size = mag),
             shape = 1,
             color = 'firebrick')
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/quake_points_mag_by_size-1.png)

However, this understates the difference between earthquakes, as their magnitudes are measured on a logarithmic scale; a M5.0 earthquake has 100 times the amplitude of a M3.0 earthquake. Scaling the circles accurately and fitting them on the map would be...a little awkward (and I also don't know enough about ggplot to map the legend's labels to the proper non-transformed values). In any case, for the purposes of this investigation, we mostly care about the *frequency* of earthquakes, rather than their actual magnitudes, so I'll leave out the size aesthetic in my examples.

Let's move on to plotting the boundaries of the United States.

Plotting the map boundaries
---------------------------

The data contained in the `us_map` variable is actually a *kind* of data frame, a **SpatialPolygonsDataFrame**, which is provided to us as part of the [**sp** package](https://cran.r-project.org/web/packages/sp/sp.pdf), which was included via the [rgdal](https://cran.r-project.org/web/packages/rgdal/index.html) package.

Since `us_map` is a data frame, it's pretty easy to plop it right into ggplot():

``` r
ggplot() +
  geom_polygon(data = us_map, aes(x = long, y = lat, group = group)) +
   theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/default_map_plot-1.png)

By default, things look a little distorted because the longitude and latitude values are treated as values on a flat, 2-dimensional plane. As we've learned, the world is *not* flat. So to have the geographical points -- in this case, the polygons that make up state boundaries -- look more like we're accustomed to on a globe, we have to *project* the longitude/latitude values to a different coordinate system.

This is a fundamental cartographic concept that is beyond my ability to concisely and intelligibly explain here, so I direct you to Michael Corey, of the Center for Investigative Reporting, and his explainer, ["Choosing the Right Map Projection"](https://source.opennews.org/en-US/learning/choosing-right-map-projection/). And Mike Bostock has a series of [excellent interactive examples showing some of the complexities of map projection](http://bost.ocks.org/mike/example/#1); I embed one of his D3 examples below:

<iframe src="http://bl.ocks.org/dannguyen/raw/36e0f357433dda000dc0/918717fa8db0d0f8d8460026b4a41815b82362de/" width="700" height="400" marginwidth="0" marginheight="0" scrolling="no">
</iframe>
Once you understand map projections, or at least are aware of their existence, applying them to ggplot() is straightforward. In the snippet below, I apply the [**Albers** projection](https://en.wikipedia.org/wiki/Albers_projection), which is the standard projection for the U.S. Census (and Geological Survey) using the **coord\_map()** function. Projecting in Albers requires a couple of parameters that [I'm just going to copy and modify from this r-bloggers example](https://rud.is/b/2015/03/15/simple-lower-us-48-albers-maps-local-no-api-citystate-geocoding-in-r/), though I assume it has something to do with [specifying the parallels needed for accurate proportions](https://cran.r-project.org/web/packages/mapproj/mapproj.pdf):

``` r
ggplot() +
  geom_polygon(data = us_map, aes(x = long, y = lat, group = group)) +
  coord_map("albers", lat0 = 38, latl = 42) + theme_classic()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/albers_us_world_plot-1.png)

### Filtering out Alaska and Hawaii

The U.S. Census boundaries only contains data for the United States. So why does our map span the entire globe? Because Alaska has the annoying property of being [both the most western *and* eastern point of the United States](https://en.wikipedia.org/wiki/Extreme_points_of_the_United_States), such that it wraps around to the other side of our coordinate system, i.e. from longitude -179 to 179.

There's obviously [a more graceful, mathematically-proper way of translating the coordinates](https://rud.is/b/2014/11/16/moving-the-earth-well-alaska-hawaii-with-r/) so that everything fits nicely on our chart. But for now, to keep things simple, let's just remove Alaska -- and Hawaii, and all the non-states -- as that gives us an opportunity to practice filtering SpatialPolygonsDataFrames.

First, we inspect the column names of `us_map`'s *data* to see which one corresponds to the *name* of each polygon, e.g. `Iowa` or `CA`:

``` r
colnames(us_map@data)
```

    ## [1] "STATEFP"  "STATENS"  "AFFGEOID" "GEOID"    "STUSPS"   "NAME"    
    ## [7] "LSAD"     "ALAND"    "AWATER"

Both **NAME** and **STUSPS** (which I'm guessing stands for *U.S. Postal Code*) will work:

``` r
head(select(us_map@data, NAME, STUSPS))
```

    ##                   NAME STUSPS
    ## 0           California     CA
    ## 1 District of Columbia     DC
    ## 2              Florida     FL
    ## 3              Georgia     GA
    ## 4                Idaho     ID
    ## 5             Illinois     IL

To filter out the data that corresponds to Alaska, i.e. `STUSPS == "AK"`:

``` r
byebye_alaska <- us_map[us_map$STUSPS != 'AK',]
```

To filter out Alaska, Hawaii, and the non-states, e.g. Guam and Washington D.C., and then assign the result to the variable `usc_map`:

``` r
x_states <- c('AK', 'HI', 'AS', 'DC', 'GU', 'MP', 'PR', 'VI')
usc_map <- subset(us_map, !(us_map$STUSPS %in% x_states))
```

Now let's map the *contiguous* United States, and, while we're here, let's change the style of the map to be in dark outline with white fill:

``` r
ggplot() +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                 fill = "white", color = "#444444", size = 0.1) +
  coord_map("albers", lat0 = 38, latl = 42)
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/albers_us_plot_outline-1.png)

### Plotting the quakes on the map

Plotting the earthquake data on top of the United States map is as easy as adding two layers together; notice how I plot the map boundaries before the points, or else the map (or rather, its *white fill*) will cover up the earthquake points:

``` r
ggplot(quakes, aes(x = longitude, y = latitude)) +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_point(size = 3,
               alpha = 0.2,
               shape = 4,
               color = 'firebrick') +
  coord_map("albers", lat0 = 38, latl = 42) +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/albers_world_misplot-1.png)

Well, that turned out poorly. The viewpoint reverts to showing the entire globe. The problem is easy to understand: the plot has to account for both the United States boundary data *and* the worldwide locations of the earthquakes.

In the next section, we'll tackle this problem by converting the earthquakes data into its own spatial-aware data frame. Then we'll *cross-reference* it with the data in `usc_map` to remove earthquakes that don't originate from within the boundaries of the contiguous United States.

Working with and filtering spatial data points
----------------------------------------------

To reiterate, `usc_map` is a **SpatialPolygonsDataFrame**, and `quakes` is a plain data frame. We want to use the geodata in `usc_map` to remove all earthquake records that don't take place within the boundaries of the U.S. contiguous states.

The first question to ask is: why don't we just filter `quakes` by one of its columns, like we did for `mag` and `type`? The problem is that while the USGS data has a `place` column, it is not U.S.-centric, i.e. there's not an easy way to say, *"Just show me records that take place within the United States"*, because `place` doesn't always mention the country:

``` r
head(quakes$place)
```

    ## [1] "56km SE of Ofunato, Japan"         "287km N of Ndoi Island, Fiji"     
    ## [3] "56km NNE of Port-Olry, Vanuatu"    "112km NNE of Vieques, Puerto Rico"
    ## [5] "92km SSW of Nikolski, Alaska"      "53km NNW of Chongdui, China"

So instead, we use the latitude/longitude coordinates stored in `usc_map` to filter out earthquakes by *their* latitude/longitude values. The math to do this from scratch is quite...labor intensive. Luckily, the **sp** library can do this work for us, we just have to first convert the `quakes` data frame into one of sp's special data frames: a **SpatialPointsDataFrame**.

``` r
sp_quakes <- SpatialPointsDataFrame(data = quakes,
                          coords = quakes[,c("longitude", "latitude")])
```

Then we assign it the same **projection** as `us_map` (note that `usc_map` also has this same projection). First let's inspect the actual projection of `us_map`:

``` r
us_map@proj4string
```

    ## CRS arguments:
    ##  +proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0

Now assign that value to `sp_quakes` (which, by default, has a `proj4string` attribute of `NA`):

``` r
sp_quakes@proj4string <- us_map@proj4string
```

Let's see what the map plot looks like. Note that in the snippet below, I don't use `sp_quakes` as the data set, but `as.data.frame(sp_quakes)`. This conversion is necessary as ggplot2 doesn't know how to deal with the SpatialPointsDataFrame (and yet it does fine with SpatialPolygonsDataFrames...whatever...):

``` r
ggplot(as.data.frame(sp_quakes), aes(x = longitude, y = latitude)) +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_point(size = 3,
               alpha = 0.2,
               shape = 4,
               color = 'firebrick') +
  coord_map("albers", lat0 = 38, latl = 42) +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/albers_world_misplot_2-1.png)

No real change...we've only gone through the process of making a spatial points data frame. Creating that spatial data frame, then converting it back to a data frame to use in ggplot() has basically no effect -- though it *would* if the geospatial data in `usc_map` had a projection that significantly transformed its lat/long coordinates.

### How to subset a spatial points data frame

To see the change that we want – just earthquakes in the contiguous United States – we *subset* the spatial points data frame, i.e. `sp_quakes`, using `usc_map`. This is actually quite easy, and uses similar notation as when subsetting a plain data frame. I actually don't know enough about basic R notation and **S4** objects to know or explain *why* this works, but it does:

``` r
sp_usc_quakes <- sp_quakes[usc_map,]
```

``` r
usc_quakes <- as.data.frame(sp_usc_quakes)

ggplot(usc_quakes, aes(x = longitude, y = latitude)) +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_point(size = 3,
               alpha = 0.5,
               shape = 4,
               color = 'firebrick')  +
  coord_map("albers", lat0 = 38, latl = 42) +
  ggtitle("M3.0+ earthquakes in the contiguous U.S. during August 2015") +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/albers_contiguous_us_quakes_month-1.png)

### Subsetting points by state

What if we want to just show earthquakes in California? We first subset `usc_map`:

``` r
ca_map <- usc_map[usc_map$STUSPS == 'CA',]
```

Then we use `ca_map` to filter `sp_quakes`:

``` r
ca_quakes <- as.data.frame(sp_quakes[ca_map,])
```

Mapping California and its quakes:

``` r
ggplot(ca_quakes, aes(x = longitude, y = latitude)) +
  geom_polygon(data = ca_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.3) +
  geom_point(size = 3,
               alpha = 0.8,
               shape = 4,
               color = 'firebrick')  +
  coord_map("albers", lat0 = 38, latl = 42) +
  theme_dan_map() +
  ggtitle("M3.0+ earthquakes in California during August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/california_august_2015-1.png)

Joining shape file attributes to a data frame
---------------------------------------------

The process of subsetting `usc_map` for each state, *then* subsetting the `sp_quakes` data frame, is a little cumbersome. Another approach is to *add a new column* to the earthquakes data frame that specifies which state the earthquake was in.

As I mentioned previously, the USGS data has a `place` column, but it doesn't follow a structured taxonomy of geographical labels and serves primarily as a human-friendly label, e.g. `"South of the Fiji Islands"` and `"Northern Mid-Atlantic Ridge"`.

So let's add the `STUSPS` column to `sp_quakes`. First, since we're done mapping just the contiguous United States, let's create a map that includes all the 50 U.S. states and store it in the variable `states_map`:

``` r
x_states <- c('AS', 'DC', 'GU', 'MP', 'PR', 'VI')
states_map <- subset(us_map, !(us_map$STUSPS %in% x_states))
```

The **sp** package's **over()** function can be used to join the rows of `sp_quakes` to the `STUSPS` column of `states_map`. In other words, the resulting data frame of earthquakes will have a `STUSPS` column, and the quakes in which the geospatial coordinates overlap with polygons in `states_map` will have a value in it, e.g. `"OK", "CA"`:

``` r
xdf <- over(sp_quakes, states_map[, 'STUSPS'])
```

Most of the `STUSPS` values in `xdf` will be `<NA>` because, most of the earthquakes do not take place in the United States. Though we see of all the United States, Oklahoma (i.e. `OK`) has experienced the most M3.0+ earthquakes by far in August 2015, twice as many as Alaska:

``` r
xdf %>% group_by(STUSPS) %>%
        summarize(count = n()) %>%
        arrange(desc(count))
```

    ## Source: local data frame [15 x 2]
    ## 
    ##    STUSPS count
    ## 1      NA   858
    ## 2      OK    55
    ## 3      AK    27
    ## 4      NV    14
    ## 5      CA     7
    ## 6      KS     4
    ## 7      HI     2
    ## 8      TX     2
    ## 9      AZ     1
    ## 10     CO     1
    ## 11     ID     1
    ## 12     MT     1
    ## 13     NE     1
    ## 14     TN     1
    ## 15     WA     1

To get a data frame of **U.S.-only quakes**, we combine `xdf` with `sp_quakes`. We then filter the resulting data frame by removing all rows in which `STUSPS` is `<NA>`:

``` r
ydf <- cbind(sp_quakes, xdf) %>% filter(!is.na(STUSPS))
states_quakes <- as.data.frame(ydf)
```

In later examples, I'll plot just the contiguous United States, so I'm going to remake the `usc_quakes` data frame in the same fashion as `states_quakes`:

``` r
usc_map <- subset(states_map, !states_map$STUSPS %in% c('AK', 'HI'))
xdf <- over(sp_quakes, usc_map[, 'STUSPS'])
usc_quakes <- cbind(sp_quakes, xdf) %>% filter(!is.na(STUSPS))
usc_quakes <- as.data.frame(usc_quakes)
```

So how is this different than before, when we derived `usc_quakes`?

``` r
old_usc_quakes <- as.data.frame(sp_quakes[usc_map,])
```

Again, the difference in our latest approach is that the resulting data frame, in this case the new `usc_quakes` and `states_quakes`, has a `STUSPS` column:

``` r
head(select(states_quakes, place, STUSPS))
```

    ##                           place STUSPS
    ## 1   119km ENE of Circle, Alaska     AK
    ## 2  73km ESE of Lakeview, Oregon     NV
    ## 3  66km ESE of Lakeview, Oregon     NV
    ## 4 18km SSW of Medford, Oklahoma     OK
    ## 5  19km NW of Anchorage, Alaska     AK
    ## 6  67km ESE of Lakeview, Oregon     NV

The `STUSPS` column makes it possible to do aggregates of the earthquakes dataframe by `STUSPS`. Note that states with 0 earthquakes for August 2015 are omitted:

``` r
ggplot(states_quakes, aes(STUSPS)) + geom_histogram(binwidth = 1) +
  scale_y_continuous(expand = c(0, 0)) +
  ggtitle("M3.0+ earthquakes in the United States, August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/histogram_states_august_2015-1.png)

Layering and arranging ggplot visuals
-------------------------------------

In successive examples, I'll be using a few more ggplot tricks and features to add a little more narrative and clarity to the basic data visualizations.

### Highlighting and annotating data

To highlight the Oklahoma data in <span style="color: #FF6600">orange</span>, I simply add another layer via `geom_histogram()`, except with data filtered for just Oklahoma:

``` r
ok_quakes <- states_quakes[states_quakes$STUSPS == 'OK',]
ggplot(states_quakes, aes(STUSPS)) +
  geom_histogram(binwidth = 1) +
  geom_histogram(data = ok_quakes, binwidth = 1, fill = '#FF6600') +
  ggtitle("M3.0+ earthquakes in the United States, August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/histogram_states_august_2015_ok_highlight-1.png)

We can add labels to the bars [with a stat\_bin() call](http://stackoverflow.com/questions/24198896/how-to-get-data-labels-for-a-histogram-in-ggplot2):

``` r
ggplot(states_quakes, aes(STUSPS)) +
  geom_histogram(binwidth = 1) +
  geom_histogram(data = ok_quakes, binwidth = 1, fill = '#FF6600') +
  stat_bin(binwidth=1, geom="text", aes(label = ..count..), vjust = -0.5) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 60)) +
  ggtitle("M3.0+ earthquakes in the United States, August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/histogram_states_august_2015_labeled-1.png)

Highlighting Oklahoma in orange on the state map also involves just making another layer call:

``` r
ok_map <- usc_map[usc_map$STUSPS == 'OK',]
ggplot(usc_quakes, aes(x = longitude, y = latitude)) +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_polygon(data = ok_map, aes(x = long, y = lat, group = group),
                   fill = "#FAF2EA", color = "#FF6600", size = 0.4) +
  geom_point(size = 2,
               alpha = 0.5,
               shape = 4,
               color = 'firebrick')  +
  coord_map("albers", lat0 = 38, latl = 42) +
  ggtitle("M3.0+ earthquakes in the United States, August 2015") +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/usc_map_ok_state_in_orange-1.png)

### Time series

These are not too different from the previous histogram examples, except that the `x`-aesthetic is set to some function of the earthquake data frame's `time` column. We use the **lubridate** package, specifically **floor\_date()** to *bin* the records to the nearest hour. Then we use **scale\_x\_date()** to scale the x-axis accordingly; the `date_breaks()` and `date_format()` functions come from the **scales** package.

For example, using the `states_quakes` data frame, here's a time series showing **earthquakes by day** of the month-long earthquake activity in the United States:

``` r
ggplot(states_quakes, aes(x = floor_date(as.Date(time), 'day'))) +
  geom_histogram(binwidth = 1) +
  scale_x_date(breaks = date_breaks("week"), labels = date_format("%m/%d")) +
  scale_y_continuous(expand = c(0, 0), breaks = pretty_breaks()) +
  ggtitle("Daily counts of M3.0+ earthquakes in the United States, August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/daily_counts_us_quakes_august_2015-1.png)

To create a stacked time-series, in which Oklahoma's portion of earthquakes is in orange, it's just a matter of adding another layer as before:

``` r
ggplot(states_quakes, aes(x = floor_date(as.Date(time), 'day'))) +
  geom_histogram(binwidth = 1, fill = "gray") +
  geom_histogram(data = filter(states_quakes, STUSPS == 'OK'), fill = "#FF6600", binwidth = 1) +
  scale_y_continuous(expand = c(0, 0), breaks = pretty_breaks()) +
  scale_x_date(breaks = date_breaks("week"), labels = date_format("%m/%d")) +
  ggtitle("Daily counts of M3.0+ earthquakes, August 2015\nOklahoma vs. all other U.S.")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/august_2015_us_histogram_ok_orange-1.png)

Or, alternatively, we can set the **fill** aesthetic to be based on the `STUSPS` column; I use the **guides()** and **scale\_fill\_manual()** functions to order the colors and labels as I want them to be:

``` r
ggplot(states_quakes, aes(x = floor_date(as.Date(time), 'day'),
                       fill = STUSPS != 'OK')) +
  geom_histogram(binwidth = 1) +
  scale_x_date(breaks = date_breaks("week"), labels = date_format("%m/%d")) +
  scale_fill_manual(values = c("#FF6600", "gray"), labels = c("OK", "Not OK")) +
  guides(fill = guide_legend(reverse = TRUE)) +
  ggtitle("Daily counts of M3.0+ earthquakes, August 2015\nOklahoma vs. all other U.S.")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/august_2015_us_histogram_ok_orange_fill_aes-1.png)

### Small multiples

ggplot2's **facet\_wrap()** function provides a convenient way to generate a grid of visualizations, one for each value of a variable, i.e. [Tufte's "small multiples", or, lattice/trellis charts](https://en.wikipedia.org/wiki/Small_multiple):

``` r
  ggplot(data = mutate(usc_quakes, week = floor_date(time, "week")),
         aes(x = longitude, y = latitude)) +
  geom_polygon(data = usc_map, aes(x = long, y = lat, group = group),
                   fill = "white", color = "#444444", size = 0.1) +
  geom_point(size = 1,
               alpha = 0.5,
               shape = 1,
               color = 'firebrick')  +
  coord_map("albers", lat0 = 38, latl = 42) +
  facet_wrap(~ week, ncol = 2) +
  ggtitle("M3.0+ Earthquakes in the contiguous U.S. by week, August 2015") +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/aug_2015_quakes_map_weekly_multiples-1.png)

### Hexbins

Dot map

``` r
ggplot() +
  geom_polygon(data = ok_map,
               aes(x = long, y = lat, group = group),
               fill = "white", color = "#666666", size = 0.5) +
  geom_point(data = ok_quakes,
              aes(x = longitude, y = latitude), color = "red", alpha = 0.4, shape = 4, size = 2.5) +
  coord_equal() +
  ggtitle("M3.0+ earthquakes in Oklahoma, August 2015") +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/aug_2015_ok_map_dot_map-1.png)

Hexbin without projection, Oklahoma

``` r
ggplot() +
  geom_polygon(data = ok_map,
               aes(x = long, y = lat, group = group),
               fill = "white", color = "#666666", size = 0.5) +
  stat_binhex(data = ok_quakes, bins = 20,
              aes(x = longitude, y = latitude), color = "#999999") +
  scale_fill_gradientn(colours = c("white", "red")) +
  coord_equal() +
  ggtitle("M3.0+ earthquakes in Oklahoma, August 2015 (Hexbin)") +
  theme_dan_map()
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/aug_2015_ok_hexbin-1.png)

When viewing the entire contiguous U.S., the shortcomings of the standard projection are more obvious. I've left on the x- and y-axis so that you can see the actual values of the longitude and latitude columns and then compare them to the Albers-projected values in the next example:

``` r
ggplot() +
  geom_polygon(data = usc_map,
               aes(x = long, y = lat, group = group),
               fill = "white", color = "#666666", size = 0.5) +
  stat_binhex(data = usc_quakes, bins = 50,
              aes(x = longitude, y = latitude), color = "#999999") +
  scale_fill_gradientn(colours = c("white", "red")) +
  coord_equal() +
  ggtitle("M3.0+ earthquakes in the contiguous U.S., August 2015")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/aug_2015_us_hexbin-1.png)

#### Projecting hexbins onto Albers

We can't rely on the **coord\_map()** function to neatly project the coordinate system to the Albers system, because **stat\_binhex()** needs to do its binning on the non-translated longitude/latitude. If that poor explanation makes no sense to you, that's OK, it barely makes sense to me.

The upshot is that if we want the visually-pleasing Albers projection for our hexbinned-map, we need to apply the projection to the data frames *before* we try to plot them.

We use the `spTransform()` function to apply the Albers coordinate system to `usc_map` and `usc_quakes`:

``` r
# store the Albers system in a variable as we need to apply it separately
# to usc_map and usc_quakes
albers_crs <- CRS("+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs")

# turn usc_quakes into a SpatialPointsDataFrame
sp_usc <-  SpatialPointsDataFrame(data = usc_quakes,
                          coords = usc_quakes[,c("longitude", "latitude")])
# give it the same default projection as usc_map
sp_usc@proj4string <- usc_map@proj4string
# Apply the Albers projection to the spatial quakes data and convert it
# back to a data frame. Note that the Albers coordinates are stored in
# latitude.2 and longitude.2
albers_quakes <- as.data.frame(spTransform(sp_usc, albers_crs))

# Apply the Albers projection to usc_map
albers_map <- spTransform(usc_map, albers_crs)
```

Note: in the `x` and `y` aesthetic for the `stat_binhex()` call, we refer to `longitude.2` and `latitude.2`. This is because `albers_quakes` is the result of two `SpaitalPointsDataFrame` conversions; each conversion creates a new `longitude` and `latitude` column.

After those extra steps, we can now hexbin our earthquake data on the Albers coordinate system; again, this is purely an aesthetic fix. As in the previous example, I've left on the x- and y-axis so you can see how the range of values that the Albers projection maps to:

``` r
ggplot() +
  geom_polygon(data = albers_map,
               aes(x = long, y = lat, group = group),
               fill = "white", color = "#666666", size = 0.5) +
  stat_binhex(data = as.data.frame(albers_quakes), bins = 50,
              aes(x = longitude.2, y = latitude.2), color = "#993333") +
  scale_fill_gradientn(colours = c("white", "red")) +
  coord_equal() +
  ggtitle("M3.0+ earthquakes in the contiguous U.S., August 2015\n(Albers projection)")
```

![](/Users/dtown/Dropbox/rprojs/ok-earthquakes-Rnotebook/md/chapter-2-basic-r-concepts_files/figure-markdown_github/aug_2015_us_quakes_albers_hexbin-1.png)

At this point, we've covered just the general range of the data-munging and visualization techniques we need to effectively analyze and visualize the historical earthquake data for the United States.

<!--
To render this file:
library(rmarkdown)
library(knitr)
setwd("~/Dropbox/rprojs/ok-earthquakes-Rnotebook/")
this_file <- 'chapter-2-basic-r-concepts.Rmd'

opts_chunk$set(fig.width = 9, fig.height = 5, dpi = 200)
render(this_file, output_dir = './builds', html_document(toc = TRUE, self_contained = F))

render(this_file, output_dir = './md', md_document(variant = "markdown_github", preserve_yaml = FALSE))
-->
