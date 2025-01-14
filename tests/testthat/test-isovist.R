# Create dummy occluders
occluders_geom <- st_sfc(
  create_occluder(1, 1, 1, 0.5),
  create_occluder(4, 1, 1.5, 0.7),
  create_occluder(7, 1, 0.8, 0.8),
  create_occluder(2, 5, 2, 1),
  create_occluder(5, 5, 1, 1.5),
  create_occluder(1, 7, 1.2, 0.6),
  create_occluder(7, 7, 1.8, 0.9))
occluders <- st_sf(id = 1:7, geometry = occluders_geom)

# Create dummy line
line_geom <- st_sfc(st_linestring(matrix(c(0, 3, 9, 3), ncol = 2, byrow = TRUE)))
line <- st_sf(id = 1, geometry = line_geom)

test_that("the correct number of viewpoints is created", {
  density = 1
  vpoints <- get_viewpoints(line, density = density)
  expect_equal(length(vpoints), ceiling(sf::st_length(line) * density))
})

test_that("density of viewpoints is a non-zero positive number", {
  expect_error(get_viewpoints(line, density = 0))
  expect_error(get_viewpoints(line, density = -1.3))
})
