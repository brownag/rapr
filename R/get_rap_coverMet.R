#' Query RAP Yearly Vegetation Cover & Meteorology Data
#'
#' Retrieves remotely sensed production estimates from the Rangeland Analysis
#' Platform (RAP) using the `coverMeteorologyV3` API endpoint. This function
#' supports querying one or more spatial features (points, lines, or polygons)
#' provided as a `terra` `SpatVector` in WGS84 longitude latitude
#' (`"EPSG:4326"`).
#'
#' For each feature - year combination, a separate request is made to the RAP
#' API, and results are returned as a combined `data.frame`. In the special case
#' of `year=NULL`) default all available years are returned in a single query.
#'
#' For more information on the API and data products, see the RAP API
#' documentation: \url{https://rangelands.app/support/71-api-documentation}
#'
#' @param aoi Area of Interest. A `SpatVector` object, or any spatial object
#'   that can be converted with `terra::vect()`. The AOI coordinates will be
#'   transformed to WGS84 longitude latitude (`"EPSG:4326"`). The AOI can be
#'   specified using point, line and polygon geometries. Each unique feature
#'   will be passed separately to the API. The result `feature` column contains
#'   the row index of the input feature from `aoi`.
#' @param year integer. Optional. Numeric year or vector of years (1986 to last
#'   full year). Default: `NULL` returns all available years.
#' @param mask logical. Exclude cropland, development, and water? Default:
#'   `TRUE`.
#' @param nodata_flag numeric. Value to use for missing data. The API encodes
#'   "NODATA" as `-99`. Default: `NA_real_` replaces `-99` with `NA`.
#'
#' @return A data.frame with yearly fractional cover data including the following
#'   columns: `"year"` (cover estimate year), ``"AFG"` (Annual Forb and Grass 
#'   cover), `"PFG"` (Perennial Forb and Grass cover), `"SHR"` (Shrub cover), 
#'   `"TRE"` (Tree cover), `"LTR"` (Litter cover), `"BGR"` (Bare Ground cover), 
#'   `"annualTemp"` (Annual average temperature in degrees Fahrenheit), 
#'   `"annualPrecip"` (Annual total precipitation in inches), 
#'   `"feature"` (feature ID, row number from `aoi`)
#' @export
#' @importFrom utils type.convert
#' @examplesIf requireNamespace("terra") && isTRUE(as.logical(Sys.getenv("R_RAPR_EXTENDED_EXAMPLES", unset=FALSE)))
#'
#' aoi <- terra::vect(data.frame(x = -119.72330, y = 36.92204),
#'                    geom = c('x', 'y'),
#'                    crs = "EPSG:4326")
#'
#' # all years (year=NULL)
#' res <- get_rap_coverMeteorlogy_table(aoi)
#' str(res)
#'
#' # specific year
#' res <- get_rap_coverMeteorology_table(aoi, year = 1992)
#' str(res)
#'
#' # multiple specific years
#' res <- get_rap_coverMeteorology_table(aoi, year = 1993:2003)
#' str(res)
#'
#' # 1 kilometer buffer around point
#' res <- get_rap_coverMeteorology_table(terra::buffer(aoi, 1000), year = 2004)
#' str(res)
#'
get_rap_coverMeteorology_table <- function(aoi, year = NULL, mask = TRUE, nodata_flag = NA_real_) {

  if (!inherits(aoi, "SpatVector")) {
    aoi <- terra::vect(aoi)
  }

  if (!requireNamespace("jsonlite")) {
    stop("package 'jsonlite' is required for the RAP API access methods")
  }

  if (nrow(aoi) == 0) {
    stop("AOI has no features", call. = FALSE)
  }

  vect_obj <- terra::project(aoi, "EPSG:4326")

  geom_type <- switch(
    terra::geomtype(vect_obj),
    "polygons" = "Polygon",
    "points" = "Point",
    "lines" = "LineString"
  )

  # Convert to GeoJSON-like list
  geojson_list <- lapply(seq_len(nrow(vect_obj)), function(i) {
    vi <- vect_obj[i,]
    if (terra::is.lines(vi)) {
      vi <- terra::as.points(vi)
    }
    geom <- terra::geom(vi, df = TRUE)
    coords <- split(geom[, c("x", "y")], geom$part)
    coords <- unname(lapply(coords, function(part) {
      unname(lapply(as.data.frame(t(part)), as.numeric))
    }))
    if (geom_type == "Point" && nrow(vi) == 1) {
      coords <- unlist(unlist(coords, recursive = FALSE), recursive = FALSE)
    } else if (geom_type == "LineString" && nrow(vi) > 1) {
      coords <- unlist(coords, recursive = FALSE)
    }
    list(
      type = "Feature",
      geometry = list(
        type = geom_type,
        coordinates = coords[which(!is.na(coords))]
      )
    )
  })

  # determine all combinations of input features and year
  if (!is.null(year)) {
    grd <- expand.grid(feature = seq_len(length(geojson_list)), year = year)
  } else {
    grd <- data.frame(feature = seq_len(length(geojson_list)))
  }

  # iterate over combination of features and years
  res <- lapply(seq_len(nrow(grd)), function(i) {
    geojson <- geojson_list[[grd$feature[i]]]
    if (!is.null(grd$year)) {
      yr <- grd$year[i]
    } else {
      yr <- NULL
    }
    geojson$properties <- list(mask = mask, year = yr)

    json <- jsonlite::toJSON(
      geojson,
      null = "null",
      auto_unbox = TRUE
    )

    # message(json)
    rap_json <- httr::RETRY(verb = "POST",
                            url = "https://us-central1-rap-data-365417.cloudfunctions.net/coverMeteorologyV3",
                            config = httr::content_type_json(),
                            body = json)

    content <- httr::content(rap_json, as = "parsed", simplifyVector = TRUE)

    if (!is.null(content)) {
      prod <- content$properties$cover
      prod_df <- as.data.frame(prod, stringsAsFactors = FALSE)
      colnames(prod_df) <- prod_df[1, ]
      prod_df <- prod_df[-1, ]
      rownames(prod_df) <- NULL
      prod_df[] <- lapply(prod_df, utils::type.convert, as.is = TRUE)
      prod_df$feature <- grd$feature[i]
      return(prod_df)
    } else {
      warning("No results for for feature ID ", grd$feature[i], call. = FALSE, immediate. = TRUE)
      return(NULL)
    }
  })

  ## example geojson feature request
  # '{"type":"Feature",
  #   "geometry": {
  #     "type":"Polygon",
  #     "coordinates":[[[-120.416024,38.086577],[-120.157845,38.228451],[-120.146859,38.47199],[-120.328133,38.417086],[-120.388558,38.318914],[-120.454476,38.193015],[-120.416024,38.086577]]]
  #   },
  #   "properties": {
  #     "mask":true,
  #     "year":null
  #   }
  #  }'
  resout <- do.call('rbind', res)
  if (!is.null(nodata_flag)) {
    resout[] <- lapply(resout, function(x) {
      x[x == -99] <- nodata_flag
      x
    })
  }
  resout
}
