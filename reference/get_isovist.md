# Calculate isovist from one or multiple viewpoints

Isovists are estimated by shooting a set of rays from each viewpoint,
and by constructing the envelope of the (partially occluded) rays.

## Usage

``` r
get_isovist(
  viewpoints,
  occluders = NULL,
  ray_num = 40,
  ray_length = 100,
  remove_holes = TRUE
)
```

## Arguments

- viewpoints:

  object of class sf_POINT or sfc_POINT

- occluders:

  object of class sf, sfc or sfg

- ray_num:

  number of rays per viewpoint. The number of rays per quadrant needs to
  be a whole number, so `ray_num` will be rounded to the closest
  multiple of four

- ray_length:

  length of rays

- remove_holes:

  whether to remove holes from the overall isovist geometry

## Value

object of class sfc_POLYGON or sfc_MULTIPOLYGON

## Examples

``` r
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
#> Geometry set for 1 feature 
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -2.5 ymin: -2.5 xmax: 2.5 ymax: 2.5
#> CRS:           NA
#> POLYGON ((2.426585 -1.463525, 2.33651 -1.680986...

# Increase number of rays to get higher resolution
get_isovist(viewpoints, occluders, ray_num = 400, ray_length = 1.5)
#> Geometry set for 1 feature 
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -2.5 ymin: -2.5 xmax: 2.5 ymax: 2.5
#> CRS:           NA
#> POLYGON ((2.49926 -1.047116, 2.498335 -1.07066,...
```
