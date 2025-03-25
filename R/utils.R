#' Create a polygon representing an occluder
#'
#' @param center_x Center x coordinate
#' @param center_y Center y coordinate
#' @param length Length of the occluder
#' @param width Width of the occluder
#'
#' @return object of class sfc_POLYGON
#' @export
#'
#' @examples
#' occluder <- create_occluder(0, 0, 10, 2)
create_occluder <- function(center_x, center_y, length, width) {
  x_min <- center_x - length / 2
  x_max <- center_x + length / 2
  y_min <- center_y - width / 2
  y_max <- center_y + width / 2
  sf::st_polygon(list(matrix(c(x_min, y_min,
                               x_max, y_min,
                               x_max, y_max,
                               x_min, y_max,
                               x_min, y_min),
                             ncol = 2,
                             byrow = TRUE)))
}
