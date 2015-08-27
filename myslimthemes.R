#' @import ggplot2
#' @import grid

theme_slim_strip <- function(){
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    panel.margin = unit(0, "cm"),
    plot.margin = unit(c(0, 0, 0, 0), "cm"),
    legend.position = "right",
    legend.key.width = unit(0.1, 'cm'),
    legend.title = element_blank(),
    strip.text.x = element_text(size = rel(3.0))
  )
}

theme_slim_chart <-  function(){
  theme_slim_strip() + theme(
    axis.text.y = element_text(color = 'black'),
    axis.ticks.y = element_line(size = 1),
    axis.ticks.x = element_blank(),
    panel.grid.major = element_line(size = 0.2, colour = "#777777",
      linetype = "dashed")
  )
}

