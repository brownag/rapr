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
.get_utm_zones <- function(x) {
  
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


#' Get Band Names by Product Name
#' @param product _character_ one of "vegetation-biomass", "vegetation-cover",
#'   "vegetation-npp", "pft", "gap", "arte", "iag", "pj"
#' @return _character_ vector of band names
#' @keywords internal
#' @noRd
.get_band_names <- function(product, replacement = "_") {
  gsub(" ", replacement, switch(
    as.character(product),
    "vegetation-biomass" = c(
      "annual forb and grass", 
      "perennial forb and grass"
    ),
    "vegetation-cover" = c(
      "annual forb and grass",
      "bare ground",
      "litter",
      "perennial forb and grass",
      "shrub",
      "tree"
    ),
    "vegetation-npp" = c(
      "annual forb and grass",
      "perennial forb and grass",
      "shrub",
      "tree"
    ),
    "pft" = c(
      "annual forb and grass",
      "bare ground",
      "litter",
      "perennial forb and grass",
      "shrub",
      "tree"
    ),
    "gap" = c(
      "gaps 25to50 cm",
      "gaps 51to100 cm",
      "gaps 100to200 cm",
      "gaps gt200 cm"
    ),
    "arte" = "artemisia spp",
    "iag" = "invasive annual grasses",
    "pj" = "pinyon juniper"
  ))
}

#' Get Band Units by Product Name
#' @param product _character_ one of "vegetation-biomass", "vegetation-cover",
#'   "vegetation-npp", "pft", "gap", "arte", "iag", "pj"
#' @return _character_ vector of band units
#' @keywords internal
#' @noRd
.get_band_units <- function(product, replacement = "_") {
  switch(
    as.character(product),
    "vegetation-biomass" = "lbs/acre",
    "vegetation-cover" =  "% cover",
    "vegetation-npp" = "kg*C/m^2",
    "pft" = "% cover",
    "gap" = "% cover",
    "arte" = "% cover",
    "iag" = "% cover",
    "pj" = "% cover"
  )
}

#' Fetch and parse rap-10m tile metadata
#' 
#' @param base_url Source URL
#' @param years Years of interest
#'
#' @return data.frame containing tile file information
#' @keywords internal
#' @noRd
fetch_tiles_metadata <- function(base_url, years) {
  response <- httr::GET(base_url)
  content <- strsplit(httr::content(response, "text"), "\n")[[1]]
  file_names <- gsub(".*>(\\w+-\\d{4}-\\d{2}-\\d{6}-\\d{7}\\.tif)<.*|.*", "\\1", content)
  m <- regexec("(\\w+)-(\\d{4})-(\\d{2})-(\\d{6})-(\\d{7})\\.tif", file_names)
  coords <- t(sapply(regmatches(file_names, m), `[`, 2:6))
  res <- data.frame(
    file_name = file_names,
    group = coords[, 1],
    year = as.numeric(coords[, 2]),
    utm_zone = as.numeric(coords[, 3]),
    lower_left_x = as.numeric(coords[, 4]),
    lower_left_y = as.numeric(coords[, 5]),
    stringsAsFactors = FALSE
  )
  subset(res, res$year %in% years)
}

#' Format gdal_utils options
#'
#' Used in `.get_rap_year_legacy()` `gdal_translate` call
#' 
#' @param x named list of GDAL options with format `list("-flag" = "value")`
#' @return character vector of option flags and values
#' @keywords internal
#' @noRd
.gdal_utils_opts <- function(x) {
  do.call('c', lapply(names(x), function(y) c(y, x[[y]])))
}