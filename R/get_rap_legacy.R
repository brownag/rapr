#' Legacy RAP Access Method
#'
#' Provides `gdal_translate` functionality through 'sf' package. This routine
#' was used in the rapr package v0.1.x (from February 2022 to April 2025).
#'
#' @param x Target extent. Derived from an sf, terra, raster, or sp object or
#'   numeric vector containing xmin, ymax, xmax, ymin in WGS84
#'   longitude/latitude decimal degrees (EPSG:4326).
#' @param years integer. Year(s) to query.
#' @param product Target data: `"vegetation-biomass"`, `"vegetation-cover"`, or
#'   `"vegetation-npp"`
#' @param version Target version: `"v3"` and/or `"v2"` (for `"rap-30m`). Ignored
#'   for `"rap-10m"`.
#' @param filename Output filename (optional; default stores in temporary files,
#'   see `terra::sources()`)
#' @param progress logical. Show progress bar? Default: missing (`NULL`) will
#'   use progress bar when three or more layers are requested.
#' @return A SpatRaster object in WGS84 geographic coordinate system
#' 
#' @importFrom terra rast writeRaster sources
#' @noRd
.get_rap_30m_legacy <- function(x, years, product, version, filename, progress) {
  
  if (!requireNamespace("sf")) {
    stop("package 'sf' is required for the legacy RAP access methods")
  }
  
  if (inherits(x, 'Spatial')) {
    x <- sf::st_as_sf(x)
  }
  
  if (!is.numeric(x) &&
      inherits(x, c('sf', 'sfc', 'wk_rcrd',
                    'SpatVector', 'SpatRaster',
                    'RasterLayer', 'RasterStack', 'RasterBrick')) &&
      requireNamespace("sf")) {
    x <- as.numeric(sf::st_bbox(sf::st_transform(sf::st_as_sf(
      data.frame(geometry = sf::st_as_sfc(sf::st_bbox(x)))
    ), crs = 'EPSG:4326')))[c(1, 4, 3, 2)]
  }
  
  mat <- expand.grid(year = years,
                     product = product,
                     version = version)
  
  if ((missing(progress) || is.null(progress)) &&
      nrow(mat) > 2) {
    progress <- TRUE
  } else {
    progress <- FALSE
  }
  
  if (progress) {
    pb <- utils::txtProgressBar(style = 3)
  }
  
  res <- terra::rast(lapply(seq_len(nrow(mat)), function (i){
    if (progress) {
      utils::setTxtProgressBar(pb, value = i / nrow(mat))
    }
    .get_rap_year_legacy(
      x       = x,
      year    = mat[i, ]$year,
      product = mat[i, ]$product,
      version = mat[i, ]$version
    )
  }))
  
  if (progress) {
    close(pb)
  }
  
  if (!missing(filename) && length(filename) > 0) {
    
    if (!dir.exists(dirname(filename))) {
      dir.create(dirname(filename), showWarnings = FALSE, recursive = TRUE)
    }
    
    terra::writeRaster(res, filename = filename)
    unlink(terra::sources(res))
    res <- terra::rast(filename)
  }
  
  res
}

#' @importFrom terra rast
.get_rap_year_legacy <- function(x, year, product, version,
                                 filename = tempfile(pattern = paste(year, product, version, sep = "_"),
                                                     fileext = '.tif')) {
  
  uri <- sprintf("/vsicurl/http://rangeland.ntsg.umt.edu/data/rap/rap-%s/%s/%s-%s-%s.tif",
                 product, version, product, version, year)
  # print(uri)
  
  sf::gdal_utils("translate",
                 source  = uri,
                 options = .gdal_utils_opts(list(
                   "-co" = "compress=lzw",
                   "-co" = "tiled=yes",
                   "-co" = "bigtiff=yes",
                   "-projwin" = x
                 )),
                 destination = filename)
  
  r <- terra::rast(filename)
  
  band_names <- .get_band_names(product)
  
  names(r) <- paste(band_names,
                    sub("vegetation-", "", product),
                    year, version, sep = "_")
  r
}
