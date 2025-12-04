# Get rays from the viewpoints within a maximum isovist

Get rays from the viewpoints within a maximum isovist

## Usage

``` r
get_rays(viewpoints, ray_num = 40, ray_length = 100)
```

## Arguments

- viewpoints:

  object of class sf_POINT or sfc_POINT

- ray_num:

  number of rays. The number of rays per quadrant needs to be a whole
  number, so `ray_num` will be rounded to the closest multiple of four

- ray_length:

  length of rays

## Value

object of class sf_LINESTRING
