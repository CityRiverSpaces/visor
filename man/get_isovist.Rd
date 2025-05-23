% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/isovist.R
\name{get_isovist}
\alias{get_isovist}
\title{Calculate isovist from one or multiple viewpoints}
\usage{
get_isovist(
  viewpoints,
  occluders = NULL,
  ray_num = 40,
  ray_length = 100,
  remove_holes = TRUE
)
}
\arguments{
\item{viewpoints}{object of class sf_POINT or sfc_POINT}

\item{occluders}{object of class sf, sfc or sfg}

\item{ray_num}{number of rays per viewpoint. The number of rays per quadrant
needs to be a whole number, so \code{ray_num} will be rounded to the closest
multiple of four}

\item{ray_length}{length of rays}

\item{remove_holes}{whether to remove holes from the overall isovist geometry}
}
\value{
object of class sfc_POLYGON or sfc_MULTIPOLYGON
}
\description{
Isovists are estimated by shooting a set of rays from each viewpoint, and
by constructing the envelope of the (partially occluded) rays.
}
\examples{
# Define viewpoints and occluder geometries
viewpoints <- sf::st_sfc(
  sf::st_point(c(-1, 1)),
  sf::st_point(c(0, 0)),
  sf::st_point(c(1, -1))
)
occluder1 <- sf::st_polygon(list(sf::st_linestring(
  cbind(c(-1, -1, -0.9, -0.9, -1),
        c(-1, -0.9, -0.9, -1, -1))
)))
occluder2 <- sf::st_polygon(list(sf::st_linestring(
  cbind(c(0.4, 0.4, 0.6, 0.6, 0.4),
        c(0.5, 0.7, 0.7, 0.5, 0.5))
)))
occluders <- sf::st_sfc(occluder1, occluder2)

# Calculare isovist based on 40 rays (default)
get_isovist(viewpoints, occluders, ray_length = 1.5)

# Increase number of rays to get higher resolution
get_isovist(viewpoints, occluders, ray_num = 400, ray_length = 1.5)
}
