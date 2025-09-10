#' Get viewpoints from an arbitrary geometry
#'
#' Generate a discrete set of points on the given geometry. If the geometry is
#' a (MULTI)POLYGON, points are generated on its boundary.
#'
#' @param x object of class sf, sfc or sfg
#' @param density number of points per distance unit
#'
#' @return object of class sfc_POINT
#'
#' @examples
#' line <- sf::st_linestring(cbind(c(-1, 1), c(0, 0)))
#' get_viewpoints(line, density = 5)
#'
#' @export
get_viewpoints <- function(x, density = 1 / 50) {
  if (density <= 0) stop("Density must be a non-zero positive number")
  if (any(sf::st_geometry_type(x) %in% c("POINT", "MULTIPOINT"))) {
    stop("Input cannot be a POINT or MULTIPOINT")
  }

  x |>
    # If input is POLYGON or MULTIPOLYGON, convert to MULTILINESTRING
    sf::st_cast("MULTILINESTRING") |>
    sf::st_cast("LINESTRING") |>
    sf::st_line_sample(density = density) |>
    sfheaders::sfc_cast("POINT") |>
    suppressWarnings()
}

#' Calculate isovist from one or multiple viewpoints
#'
#' Isovists are estimated by shooting a set of rays from each viewpoint, and
#' by constructing the envelope of the (partially occluded) rays.
#'
#' @param viewpoints object of class sf_POINT or sfc_POINT
#' @param occluders object of class sf, sfc or sfg
#' @param ray_num number of rays per viewpoint. The number of rays per quadrant
#'   needs to be a whole number, so `ray_num` will be rounded to the closest
#'   multiple of four
#' @param ray_length length of rays
#' @param remove_holes whether to remove holes from the overall isovist geometry
#'
#' @return object of class sfc_POLYGON or sfc_MULTIPOLYGON
#'
#' @examples
#' # Define viewpoints and occluder geometries
#' viewpoints <- sf::st_sfc(
#'   sf::st_point(c(-1, 1)),
#'   sf::st_point(c(0, 0)),
#'   sf::st_point(c(1, -1))
#' )
#' occluder1 <- sf::st_polygon(list(sf::st_linestring(
#'   cbind(c(-1, -1, -0.9, -0.9, -1),
#'         c(-1, -0.9, -0.9, -1, -1))
#' )))
#' occluder2 <- sf::st_polygon(list(sf::st_linestring(
#'   cbind(c(0.4, 0.4, 0.6, 0.6, 0.4),
#'         c(0.5, 0.7, 0.7, 0.5, 0.5))
#' )))
#' occluders <- sf::st_sfc(occluder1, occluder2)
#'
#' # Calculare isovist based on 40 rays (default)
#' get_isovist(viewpoints, occluders, ray_length = 1.5)
#'
#' # Increase number of rays to get higher resolution
#' get_isovist(viewpoints, occluders, ray_num = 400, ray_length = 1.5)
#' @export
get_isovist <- function(viewpoints, occluders = NULL, ray_num = 40,
                        ray_length = 100, remove_holes = TRUE) {
  rays <- get_rays(viewpoints, ray_num = ray_num, ray_length = ray_length)

  rays_occluded <- occlude_rays(rays, occluders = occluders)

  isovists <- get_isovists(rays_occluded)

  merge_isovists(isovists, remove_holes = remove_holes)
}

#' Get rays from the viewpoints within a maximum isovist
#'
#' @param viewpoints object of class sf_POINT or sfc_POINT
#' @param ray_num number of rays. The number of rays per quadrant needs to be a
#'   whole number, so `ray_num` will be rounded to the closest multiple of four
#' @param ray_length length of rays
#'
#' @return object of class sf_LINESTRING
#' @keywords internal
get_rays <- function(viewpoints, ray_num = 40, ray_length = 100) {
  # Sanity checks on input
  if (!all(sf::st_is(viewpoints, "POINT"))) {
    stop("viewpoints must consist of POINT geometries")
  }
  if (ray_num <= 0) stop("ray_num must be a positive number")
  ray_num_rounded <- round(ray_num / 4) * 4
  if (ray_num_rounded != ray_num) warning(sprintf(
    "ray_num is rounded to %s", ray_num_rounded
  ))
  ray_num <- as.integer(ray_num_rounded)
  if (ray_length <= 0) stop("ray_length must be larger than zero")

  # Generate points on the maximum isovist of the given length
  maxisovists <- sf::st_buffer(viewpoints, dist = ray_length,
                               nQuadSegs = ray_num / 4)
  maxisovists_df <- sfheaders::sfc_to_df(maxisovists)
  is_point_unique <- duplicated(maxisovists_df$polygon_id)
  maxisovists_points <- maxisovists_df[is_point_unique, ]

  # The points on the maximum isovist will be the ray endpoints
  ray_end_coords <- maxisovists_points[, c("x", "y")]

  # The viewpoints (centers of the max isovists) will be the ray start points
  viewpoints_coords <- sf::st_coordinates(viewpoints)
  ray_start_coords <- matrix(rep(viewpoints_coords, each = ray_num),
                             ncol = 2,
                             dimnames = list(NULL, c("x", "y")))

  # Set the ray data frame up with all the ray coordinates
  ray_df <- as.data.frame(rbind(ray_start_coords, ray_end_coords))

  # Generate ray identifiers and label each point with its ray identifier
  ray_num_tot <- length(viewpoints) * ray_num
  ray_id <- seq_len(ray_num_tot)
  ray_df["ray_id"] <- rep(ray_id, times = 2)  # repeat for start and end points

  # Also keep track of which isovist each point (ray) belongs to
  isovist_id <- maxisovists_points$polygon_id
  ray_df["isovist_id"] <- rep(isovist_id, times = 2)  # repeat, as above

  # Sort using ray identifiers, convert data frame to sf object
  rays <- sfheaders::sf_linestring(ray_df[order(ray_df$ray_id), ],
                                   x = "x", y = "y", linestring_id = "ray_id",
                                   keep = TRUE)  # keep isovist ID labels

  # Add CRS info and return
  sf::st_crs(rays) <- sf::st_crs(viewpoints)
  rays
}

#' Determine the non-occluded segments of the rays
#'
#' @param rays object of class sf_LINESTRING
#' @param occluders object of class sf, sfc or sfg
#'
#' @return object of class sf_LINESTRING
#' @keywords internal
occlude_rays <- function(rays, occluders = NULL) {
  if (is.null(occluders)) {
    return(rays)
  }
  ray_geoms <- sf::st_geometry(rays)
  occluder_geoms <- sf::st_geometry(occluders)

  # Find out which rays and occluders intersect each other
  intersections <- sf::st_intersects(ray_geoms, occluder_geoms)
  ray_intersects_occluders <- lengths(intersections) > 0
  occluder_intersects_rays <- unique(unlist(intersections))

  # Filter the only features intersecting each others
  rays_intersect <- ray_geoms[ray_intersects_occluders]
  occluders_intersect <- occluder_geoms[occluder_intersects_rays]
  occluders_intersect <- sf::st_union(occluders_intersect)

  # Determine which rays are fully within the occluders and will thus be dropped
  rays_within_occluders <- sf::st_within(rays_intersect,
                                         occluders_intersect,
                                         sparse = FALSE)

  # Determine the ray segments that do not overlap with the occluders. For each
  # ray the segments form (multi)-linestrings. Fully-occluded rays are dropped
  diffs <- sf::st_difference(rays_intersect, occluders_intersect)

  # By casting `diffs` to linestrings, we keep only the first segment of each
  # ray, which, by construction, runs from the original viewpoint to the first
  # occluder (if any)
  rays_occluded <- sf::st_cast(diffs, "LINESTRING", group_or_split = FALSE) |>
    suppressWarnings()

  # Determine the indices of the partially-occluded rays, i.e. the ones that
  # intersect the occluders and are not fully within the occluders
  idx <- which(ray_intersects_occluders)[!rays_within_occluders]

  # Update the occluded ray geometries and return the sf(c) object
  ray_geoms[idx] <- rays_occluded
  sf::st_set_geometry(rays, ray_geoms)
}

#' Construct isovist from (partially occluded) rays
#'
#' @param rays object of class sf, including the "isovist_id" attribute
#'
#' @return object of class sfc_POLYGON
#' @keywords internal
get_isovists <- function(rays) {
  # Extract ray endpoints
  ray_points <- sfheaders::sf_to_df(rays, fill = TRUE)  # fill keeps all columns
  is_ray_endpoint <- duplicated(ray_points$linestring_id)
  ray_endpoints <- ray_points[is_ray_endpoint, ]

  # Ray endpoints are recasted into polygons using the original isovist IDs
  isovists <- sfheaders::sfc_polygon(ray_endpoints,
                                     x = "x", y = "y",
                                     polygon_id = "isovist_id",
                                     close = TRUE)
  # Add CRS info and return
  sf::st_crs(isovists) <- sf::st_crs(rays)
  isovists
}

#' Merge the viewpoint isovists
#'
#' @param isovists object of class sf, sfc or sfg
#' @param remove_holes whether to remove holes from the overall isovist geometry
#'
#' @return object of class sfc_POLYGON or sfc_MULTIPOLYGON
#' @keywords internal
merge_isovists <- function(isovists, remove_holes = TRUE) {
  isovist_union <- sf::st_union(isovists)
  if (remove_holes) isovist_union <- sfheaders::sf_remove_holes(isovist_union)
  isovist_union
}
