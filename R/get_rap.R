#' Get Rangeland Analysis Platform (RAP) Grids
#'
#' @param x Target extent. Derived from an sf, terra, raster or sp object or
#'   numeric vector containing xmin, ymax, xmax, ymin in WGS84
#'   longitude/latitude decimal degrees (EPSG:4326).
#' @param years integer. Year(s) to query
#' @param product Target data: `"vegetation-biomass"` and/or
#'   `"vegetation-cover"` (for `"rap-30m"`) and `"pft"` (plant functional type
#'   cover), `"gap"` (canopy gap), `"arte"` (Artemisia spp. cover), `"iag"`
#'   (invasive annual grass cover), `"pj"` (pinyon juniper cover))
#' @param filename Output filename (optional; default stores in temporary files,
#'   see `terra::sources()`)
#' @param ... Additional arguments passed to internal RAP query function and
#'   `[terra::writeRaster()]`
#' @param source Grid sources. Options include `"rap-30m"` (default; Landsat)
#'   and `"rap-10m"` (Sentinel 2).
#' @param version Target version: `"v3"` and/or `"v2"` (for `"rap-30m`). Ignored
#'   for `"rap-10m"`.
#' @param legacy _logical_. Use legacy (gdal_translate) method? Default: `TRUE`
#'   (applies only to `source="rap-30m"`).
#' @param progress logical. Show progress bar? Default: missing (`NULL`) will
#'   use progress bar when three or more layers are requested.
#' @details You can query annual biomass and cover (versions 2 and 3) from 1986
#'   to present
#'
#'   - `product = "vegetation-biomass"` returns two layers per year:
#'     - `"annual forb and grass"`, `"perennial forb and grass"` (**lbs / acre**)
#'
#'   - `product = "vegetation-cover"` returns six layers per year:
#'     - `"annual forb and grass"`, `"bare ground"`, `"litter"`, `"perennial forb and grass"`, `"shrub"`, `"tree"` (**% cover**)
#'
#'   When a `filename` argument is not specified, unique temporary files will be
#'   generated. The resulting SpatRaster object will retain reference to these
#'   files, and you can remove them manually with
#'   `unlink(terra::sources(<SpatRaster))`.
#'
#'   When a `filename` _is_ specified, temporary files will be removed after the
#'   result (often a multi- year/layer/product) SpatRaster is written to new
#'   file.
#'
#'   In lieu of a spatial object from \{terra\}, \{raster\}, \{sf\} or \{sp\}
#'   packages you may specify a bounding box using a numeric vector containing
#'   `xmin`, `ymax`, `xmax`, `ymin` in WGS84 longitude/latitude decimal degrees
#'   (corresponding to order used in `gdal_translate` `-projwin` option). e.g.
#'   `get_rap(x = c(-120, 37, -119.99, 36.99), ...)`.
#'
#' ```
#' (1: xmin, 2: ymax)--------------------------|
#'         |                                   |
#'         |         TARGET EXTENT             |
#'         |  x = c(xmin, ymax, xmax, ymin)    |
#'         |                                   |
#'         |---------------------------(3: xmax, 4: ymin)
#' ```
#' @return a SpatRaster containing the requested product layers by year.
#'   Native cell resolution of `"rap-30m"` is ~30m x 30m in WGS84 geographic coordinate system.
#'   Native cell resolution of `"rap-10m"` is 10m x 10m in WGS84 Universal Transverse Mercator (UTM) zone.

#' @export
get_rap <- function(x,
                    years,
                    product,
                    filename = NULL,
                    ...,
                    source = "rap-30m",
                    version = "v3",
                    legacy = TRUE,
                    progress = NULL) {

  source <- match.arg(tolower(source), choices = c("rap-30m", "rap-10m"))
  
  if (source == "rap-10m") {
    # RAP 10m through new interface
    
    # version currently ignored for RAP 10m data
    product <- match.arg(tolower(product), choices = c("pft", "gap", "arte", "iag", "pj"), several.ok = TRUE)
    
    # TODO: implement progress bar? verbose argument is similar but provides more info
    .get_rap_internal(
      x, 
      years = years, 
      product = product, 
      filename = filename, 
      ...
    )
  } else if (source == "rap-30m" && isTRUE(legacy)) {
    # RAP 30m through old interface
    version <- match.arg(tolower(version), choices = c("v3", "v2"), several.ok = TRUE)
    
    product <- match.arg(tolower(product), choices = c("vegetation-biomass", "vegetation-cover"), several.ok = TRUE)
    
    .get_rap_30m_legacy(
      x,
      years = years,
      product = product,
      filename = filename,
      version = version,
      progress = progress
    )
  } else {
    # RAP 30m through new interface
    stop("RAP 30m data can only be accessed through the legacy interface at this time. Please set `legacy=TRUE`", call. = FALSE)
  }
  
}
