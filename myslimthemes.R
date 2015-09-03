#' @import ggplot2
#' @import grid

theme_dan <- function(){
  theme_minimal() +
  theme(
    axis.text = element_text(colour = "#555555"),
    axis.line = element_line(size = 0.1, linetype = "solid", color = "#444444"),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    legend.position = "right",
    legend.key.width = unit(0.1, 'cm'),
    legend.title = element_blank(),
    panel.background = element_blank(),
    panel.grid.major = element_line(size = 0.3, colour = "#666666",
      linetype = "dotted"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    plot.title = element_text(size = 15, vjust=2)
  )
}



theme_dan_map <- function(){
    theme_dan() + theme(
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      panel.grid.major = element_blank()
    )
}




theme_dan_grid <- function(){
    theme_dan() + theme(
      plot.margin = unit(c(0, 0, 0, 0), "cm"),
      panel.margin = unit(0, "cm"),
      strip.text.x = element_text(size = rel(1.2)),
      axis.text.x = element_blank(),
      panel.grid.major = element_blank()
    )
}
