# Get viewpoints from an arbitrary geometry

Generate a discrete set of points on the given geometry. If the geometry
is a (MULTI)POLYGON, points are generated on its boundary.

## Usage

``` r
get_viewpoints(x, density = 1/50)
```

## Arguments

- x:

  object of class sf, sfc or sfg

- density:

  number of points per distance unit

## Value

object of class sfc_POINT

## Examples

``` r
line <- sf::st_linestring(cbind(c(-1, 1), c(0, 0)))
get_viewpoints(line, density = 5)
#> Geometry set for 10 features 
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -0.9 ymin: 0 xmax: 0.9 ymax: 0
#> CRS:           NA
#> First 5 geometries:
#> POINT (-0.9 0)
#> POINT (-0.7 0)
#> POINT (-0.5 0)
#> POINT (-0.3 0)
#> POINT (-0.1 0)
```
