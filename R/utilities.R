#' Determine UTM Zones for Region of Interest
#' 
#' Helper function to determine the UTM zone(s) of a region of interest.
#' 
#' Used for filtering UTM tile sets in `.get_rap_internal()` method for RAP 10m data.
#' 
#' @param x A SpatVector object. 
#'
#' @return _numeric_. Vector of UTM zone numbers.
#' @keywords internal 
#' @noRd
get_utm_zones <- function(x) {
  
  if (inherits(x, 'sf')) {
    x <- terra::vect(x)
  }
  
  if (!inherits(x, 'SpatVector')) {
    stop("`x` should be a SpatVector object")
  }
  
  roi_wgs84 <- terra::project(x, "EPSG:4326")
  lon <- terra::crds(roi_wgs84)[, 1]
  res <- floor((lon + 180) / 6) + 1
  
  seq(from = min(res), to = max(res))
}

#' gdal_utils options
#'
#' Used in `.get_rap_year_legacy()` `gdal_translate` call``
#' 
#' @param x named list of GDAL options with format `list("-flag" = "value")`
#' @return character vector of option flags and values
#' @keywords internal
#' @noRd
.gdal_utils_opts <- function(x) {
  do.call('c', lapply(names(x), function(y) c(y, x[[y]])))
}
