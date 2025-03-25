# Create dummy occluders
occluders_geom <- sf::st_sfc(
  create_occluder(1, 1, 1, 0.5),
  create_occluder(4, 1, 1.5, 0.7),
  create_occluder(7, 1, 0.8, 0.8),
  create_occluder(2, 5, 2, 1),
  create_occluder(5, 5, 1, 1.5),
  create_occluder(1, 7, 1.2, 0.6),
  create_occluder(7, 7, 1.8, 0.9)
)
occluders <- sf::st_sf(id = 1:7, geometry = occluders_geom)

# Create dummy line
line_geom <- sf::st_sfc(
  sf::st_linestring(matrix(c(0, 3, 9, 3), ncol = 2, byrow = TRUE))
)
line <- sf::st_sf(id = 1, geometry = line_geom)

test_that("the correct number of viewpoints is created", {
  density <- 1
  vpoints <- get_viewpoints(sf::st_geometry(line), density = density)
  expect_equal(length(vpoints), ceiling(sf::st_length(line) * density))
})

test_that("density of viewpoints is a non-zero positive number", {
  expect_error(get_viewpoints(line, density = 0))
  expect_error(get_viewpoints(line, density = -1.3))
})

test_that("input cannot be a POINT or MULTIPOINT", {
  expect_error(get_viewpoints(sf::st_point(c(1, 1))))
  expect_error(get_viewpoints(
    sf::st_multipoint(matrix(c(1, 1, 2, 2), ncol = 2, byrow = TRUE))
  ))
})

test_that("POLYGON input is converted to LINESTRING", {
  density <- 1
  line <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(
    list(rbind(c(0, 0), c(0, 1), c(1, 1), c(1, 0), c(0, 0)))
  )))
  # Get viewpoints with POLYGON as input
  vpoints <- get_viewpoints(line, density = density)
  # Cast to LINESTRING to allow for length calculation
  line <- sf::st_cast(line, "MULTILINESTRING") |>
    sf::st_cast("LINESTRING")
  expect_equal(length(vpoints), ceiling(sf::st_length(line) * density))
})

test_that("An isovist is properly constructed for a single viewpoint", {
  viewpoint <- sf::st_sfc(sf::st_point(c(6, 3)))
  ray_length <- 5
  isovist <- get_isovist(viewpoint, occluders, ray_length = ray_length)
  expect_true(inherits(isovist, "sfc"))
  expect_equal(length(isovist), 1)
  expect_true(sf::st_is(isovist, "POLYGON"))
  # isovist should be smaller than unoccluded buffer
  buffer <- sf::st_buffer(viewpoint, ray_length)
  expect_true(sf::st_contains(buffer, isovist, sparse = FALSE))
})

test_that("An isovist is properly constructed for multiple viewpoints", {
  viewpoints <- sf::st_cast(sf::st_sample(line_geom, 3), "POINT")
  ray_length <- 5
  isovist <- get_isovist(viewpoints, occluders, ray_length = ray_length)
  expect_true(inherits(isovist, "sfc"))
  expect_equal(length(isovist), 1)
  expect_true(sf::st_is(isovist, "POLYGON"))
  # isovist should be smaller than unoccluded buffer
  buffer <- sf::st_union(sf::st_buffer(viewpoints, ray_length))
  expect_true(sf::st_contains(buffer, isovist, sparse = FALSE))
})

test_that("Rays are properly constructed from a list of viewpoints", {
  ray_length <- 1
  ray_num <- 160
  viewpoints <- sf::st_sfc(
    sf::st_point(c(0, 1)), sf::st_point(c(1, 1)), sf::st_point(c(1, 0))
  )
  rays <- get_rays(viewpoints, ray_num = ray_num, ray_length = ray_length)
  expect_equal(nrow(rays), length(viewpoints) * ray_num)
  expect_true(all(sf::st_is(rays, "LINESTRING")))
  expect_contains(sf::st_length(rays), ray_length)
})

test_that("Rays construction fails for incorrect input arguments", {
  ray_length <- 1
  ray_num <- 160
  viewpoints <- sf::st_sfc(
    sf::st_point(c(0, 1)), sf::st_point(c(1, 1)), sf::st_point(c(1, 0))
  )
  expect_no_error(get_rays(viewpoints, ray_num = ray_num,
                           ray_length = ray_length))
  # ray_num must be a whole number
  expect_error(get_rays(viewpoints, ray_num = 0.1, ray_length = ray_length))
  # ray_length must be positive
  expect_error(get_rays(viewpoints, ray_num = ray_num, ray_length = 0))
  # viewpoints must consist of point geometries
  expect_error(get_rays(line, ray_num = ray_num, ray_length = 0))
})

test_that("Occluding rays without occluders return untouched rays", {
  ray_geoms <- sf::st_sfc(
    sf::st_linestring(cbind(c(0, 1), c(0, 0))),
    sf::st_linestring(cbind(c(0, 0), c(0, 1))),
    sf::st_linestring(cbind(c(0, -1), c(0, 0))),
    sf::st_linestring(cbind(c(0, 0), c(0, -1)))
  )
  rays <- sf::st_as_sf(ray_geoms)
  occluded_rays <- occlude_rays(rays)
  expect_setequal(ray_geoms, sf::st_geometry(occluded_rays))
})

test_that("Occluding rays with a polygon returns modified rays", {
  ray_geoms <- sf::st_sfc(
    sf::st_linestring(cbind(c(0, 0), c(0, 1))),
    sf::st_linestring(cbind(c(0, 1), c(0, 0))),
    sf::st_linestring(cbind(c(0, -1), c(0, 0))),
    sf::st_linestring(cbind(c(0, 0), c(0, -1)))
  )
  rays <- sf::st_as_sf(ray_geoms)
  occluder <- create_occluder(-0.5, 0, 0.2, 0.2)

  actual <- occlude_rays(rays, occluders = occluder)
  expected <- sf::st_sfc(
    sf::st_linestring(cbind(c(0, 1), c(0, 0))),
    sf::st_linestring(cbind(c(0, 0), c(0, 1))),
    sf::st_linestring(cbind(c(0, -0.4), c(0, 0))),
    sf::st_linestring(cbind(c(0, 0), c(0, -1)))
  )
  expect_setequal(sf::st_geometry(actual), expected)
})

test_that("get_isovists transforms rays to polygons", {
  center_isovist_1 <- sf::st_point(c(0, 0))
  points_isovist_1 <- sf::st_sfc(
    sf::st_point(c(0, 1)), sf::st_point(c(1, 0)),
    sf::st_point(c(0, -1)), sf::st_point(c(-1, 0))
  )
  center_isovist_2 <- sf::st_point(c(2, 0))
  points_isovist_2 <- sf::st_sfc(
    sf::st_point(c(2, 1)), sf::st_point(c(3, 0)), sf::st_point(c(2, -1))
  )
  ray_geoms <- sf::st_sfc(
    sf::st_linestring(c(center_isovist_1, points_isovist_1[[1]])),
    sf::st_linestring(c(center_isovist_1, points_isovist_1[[2]])),
    sf::st_linestring(c(center_isovist_1, points_isovist_1[[3]])),
    sf::st_linestring(c(center_isovist_1, points_isovist_1[[4]])),
    sf::st_linestring(c(center_isovist_2, points_isovist_2[[1]])),
    sf::st_linestring(c(center_isovist_2, points_isovist_2[[2]])),
    sf::st_linestring(c(center_isovist_2, points_isovist_2[[3]]))
  )
  rays <- sf::st_as_sf(ray_geoms)
  rays["isovist_id"] <- c(1, 1, 1, 1, 2, 2, 2)
  isovists <- get_isovists(rays)
  # Check that the isovist boundaries contain all original points
  expect_setequal(sf::st_cast(isovists[1], "POINT"), points_isovist_1)
  expect_setequal(sf::st_cast(isovists[2], "POINT"), points_isovist_2)
})

test_that("merge_isovists returns the merged polygon, with or without holes", {
  isovist_1 <-  sf::st_buffer(sf::st_point(c(0, 0)), 2)
  isovist_2 <-  sf::st_buffer(sf::st_point(c(2, 0)), 2)
  hole <- sf::st_buffer(sf::st_point(c(-1, 0)), 0.5)
  isovist_1_hole <- sf::st_difference(isovist_1, hole)
  isovists <- sf::st_sfc(isovist_1, isovist_2)
  isovists_hole <- sf::st_sfc(isovist_1_hole, isovist_2)
  # if remove_holes is FALSE, hole remains
  actual <- merge_isovists(isovists_hole, remove_holes = FALSE)
  expected <- sf::st_union(isovists_hole)
  expect_equal(actual, expected)
  # if remove_holes is TRUE, hole is removed
  actual <- merge_isovists(isovists_hole, remove_holes = TRUE)
  expected <- sf::st_union(isovists)
  expect_equal(actual, expected)
})
