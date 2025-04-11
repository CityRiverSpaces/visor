
<!-- README.md is generated from README.Rmd. Please edit that file -->

# visor

<!-- badges: start -->

[![R-CMD-check](https://github.com/CityRiverSpaces/visor/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CityRiverSpaces/visor/actions/workflows/R-CMD-check.yaml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15133420.svg)](https://doi.org/10.5281/zenodo.15133420)
[![CRAN-status](https://www.r-pkg.org/badges/version/visor)](https://CRAN.R-project.org/package=visor)
<!-- badges: end -->

The goal of visor is to provide a set of tools for visibility analysis.

## Installation

You can install the released version of visor from
[CRAN](https://cran.r-project.org) with:

``` r
install.packages("visor")
```

You can install the development version of visor from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("CityRiverSpaces/visor")
```

## Example

This is a basic example which shows you how to use visor to calculate
the isovist for view points on an arbitrary geometry (a line) and a set
of occluders:

``` r
library(visor)
library(sf)

# Define occluder geoemtries
occluders <- st_sfc(
  create_occluder(1, 1, 1, 0.5),
  create_occluder(4, 1, 1.5, 0.7),
  create_occluder(7, 1, 0.8, 0.8),
  create_occluder(2, 5, 2, 1),
  create_occluder(5, 5, 1, 1.5),
  create_occluder(1, 7, 1.2, 0.6),
  create_occluder(7, 7, 1.8, 0.9)
)

# Define the viewpoint source geometry
line <- st_sfc(
  st_linestring(matrix(c(0, 3, 9, 3), ncol = 2, byrow = TRUE))
)

# Generate viewpoints
vpoints <- get_viewpoints(line, density = 1)

# Calculate isovist
isovist <- get_isovist(vpoints, occluders, ray_num = 160, ray_length = 5,
                       remove_holes = FALSE)

plot(isovist, col = "blue")
plot(occluders, col = "grey", add = TRUE)
plot(line, col = "lightblue", add = TRUE)
plot(vpoints, col = "red", add = TRUE)
```

<img src="man/figures/README-example-1.png" width="100%" />
