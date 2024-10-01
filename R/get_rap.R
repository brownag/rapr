#' Get Rangeland Analysis Platform (RAP) Grids
#'
#' @param x Target extent. Derived from an sf, terra, raster or sp object or numeric vector containing xmin, ymax, xmax, ymin in WGS84 longitude/latitude decimal degrees (EPSG:4326).
#' @param years integer. Year(s) to query
#' @param product Target data: `"vegetation-biomass"` and/or `"vegetation-cover"`
#' @param version Target version: `"v3"` and/or `"v2"`
#' @param filename Output filename (optional; default stores in temporary files, see `terra::sources()`)
#' @param progress logical. Show progress bar? Default: missing (`NULL`) will use progress bar when three or more layers are requested.
#' @details You can query annual biomass and cover (versions 2 and 3) from 1986 to present
#'
#'   - `product = "vegetation-biomass"` returns two layers per year:
#'     - `"annual forb and grass"`, `"perennial forb and grass"` (**lbs / acre**)
#'
#'   - `product = "vegetation-cover"` returns six layers per year:
#'     - `"annual forb and grass"`, `"bare ground"`, `"litter"`, `"perennial forb and grass"`, `"shrub"`, `"tree"` (**% cover**)
#'
#' When a `filename` argument is not specified, unique temporary files will be generated. The resulting SpatRaster object will retain reference to these files, and you can remove them manually with `unlink(terra::sources(<SpatRaster))`.
#'
#' When a `filename` _is_ specified, temporary files will be removed after the result (often a multi- year/layer/product) SpatRaster is written to new file.
#'
#' In lieu of a spatial object from {terra}, {raster}, {sf} or {sp} packages you may specify a bounding box using a numeric vector containing `xmin`, `ymax`, `xmax`, `ymin` in WGS84 longitude/latitude decimal degrees (corresponding to order used in `gdal_translate` `-projwin` option). e.g. `get_rap(x = c(-120, 37, -119.99, 36.99), ...)`.
#'
#' ```
#' (1: xmin, 2: ymax)--------------------------|
#'         |                                   |
#'         |         TARGET EXTENT             |
#'         |  x = c(xmin, ymax, xmax, ymin)    |
#'         |                                   |
#'         |---------------------------(3: xmax, 4: ymin)
#' ```
#' @return a SpatRaster containing the requested vegetation-biomass and/or vegetation-cover layers by year. Native cell resolution is ~30m x 30m in WGS84 decimal degrees.
#' @importFrom terra rast writeRaster sources
#' @importFrom sf st_bbox st_transform st_crs st_as_sf st_as_sfc
#' @importFrom utils txtProgressBar setTxtProgressBar
#' @export
get_rap <- function(x,
                    years = c(1986, 1996, 2006, 2016),
                    filename = NULL,
                    product = c("vegetation-biomass", "vegetation-cover"),
                    version = "v3",
                    progress = NULL) {

  version <- match.arg(version, choices = c("v3", "v2"), several.ok = TRUE)
  product <- match.arg(product, choices = c("vegetation-biomass", "vegetation-cover"), several.ok = TRUE)

  if (inherits(x, 'Spatial')){
    x <- sf::st_as_sf(x)
  }

  if (!is.numeric(x) &&
      (inherits(x, 'sf') ||
       inherits(x, 'sfc') ||
       inherits(x, 'wk_rcrd') ||
       inherits(x, 'SpatRaster') ||
       inherits(x, 'SpatVector') ||
       inherits(x, 'RasterLayer') ||
       inherits(x, 'RasterStack') ||
       inherits(x, 'RasterBrick') )) {

    if (requireNamespace("sf")) {
      x <- as.numeric(sf::st_bbox(sf::st_transform(sf::st_as_sf(
          data.frame(geometry = sf::st_as_sfc(sf::st_bbox(x)))
        ), crs = 'EPSG:4326')))[c(1, 4, 3, 2)]
    }

  }

  mat <- expand.grid(year = years,
                     product = product,
                     version = version)

  if (missing(progress) || is.null(progress)) {
    if (nrow(mat) > 2) {
      progress <- TRUE
    } else progress <- FALSE
  }

  if (progress) {
    pb <- utils::txtProgressBar(style = 3)
  }

  res <- terra::rast(lapply(1:nrow(mat), function (i){
    if (progress) {
      utils::setTxtProgressBar(pb, value = i / nrow(mat))
    }
    .get_rap_year(
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

#' gdal_utils options
#'
#' @param x named list of GDAL options with format `list("-flag" = "value")`
#' @return character vector of option flags and values
#' @keywords internal
#' @noRd
.gdal_utils_opts <- function(x) {
  do.call('c', lapply(names(x), function(y) c(y, x[[y]])))
}

#' @importFrom sf gdal_utils
#' @importFrom terra rast
.get_rap_year <- function(x, year, product, version,
                          filename = tempfile(pattern = paste0(year, product, version, sep = "_"),
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

  band_names <- switch(as.character(product),
                       "vegetation-biomass" = c("annual forb and grass", "perennial forb and grass"),
                       "vegetation-cover"   = c("annual forb and grass", "bare ground", "litter",
                                                "perennial forb and grass", "shrub", "tree"))
  names(r) <- paste(gsub(" ", "_", band_names),
                    sub("vegetation-", "", product),
                    year, version, sep = "_")
  r
}
