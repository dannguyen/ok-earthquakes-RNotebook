## Investigating Oklahoma Earthquakes with R and ggplot2

An R Notebook using ggplot2 and rgdal, among other libraries to examine the surge in Oklahoma earthquakes.

By [Dan Nguyen](https://twitter.com/dancow) for Stanford Computational Journalism.

Write up is in progress. But here's an animated GIF I made, painstakingly created via [R and ImageMagick and shell-fu](make-animated-gif.R):

![Animated GIF of U.S. earthquakes above 3.0 magnitude](images/optimized-movie-quakes-OK.gif?raw=true)


## Development notes

### Running the R notebooks

The R notebooks use __absolute paths__ for their cache directories, e.g. `/tmp/rstudio-cache/ok-earthquakes`. If you're on a Windows system, you'll likely have to change all of these to whatever Windows' equivalent to `/tmp` is.
