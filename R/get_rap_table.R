#' Query RAP Tabular Data
#'
#' Retrieves remotely sensed production or cover estimates from the Rangeland 
#' Analysis Platform (RAP) using the tabular data API endpoints. This function
#' supports querying one or more spatial features (points, lines, or polygons)
#' provided as a `terra` `SpatVector` object, or any spatial object that can be 
#' converted with `terra::vect()`. See Details for the products available.
#'
#' For each feature - year combination, a separate request is made to the RAP
#' API, and results are returned as a combined `data.frame`. In the special case
#' of (`years=NULL`) default, all available years are returned in a single query.
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
#' @param years integer. Optional. Numeric year or vector of years (1986 to last
#'   full year). Default: `NULL` returns all available years.
#' @param product Target data: `"cover"`, `"coverMeteorology"`, 
#' `"production"`, or `"production16day"`.
#' @param version Target version: `"V3"`.
#' @param mask logical. Exclude cropland, development, and water? Default:
#'   `TRUE`.
#' @param nodata_flag numeric. Value to use for missing data. The API encodes
#'   "NODATA" as `-99`. Default: `NA_real_` replaces `-99` with `NA`.
#' @details
#'    
#' ## Products Overview
#'
#' You can query several Landsat derived biomass, cover, and meteorological 
#' products from 1986 to present:
#'
#'   - `"cover"` -- yearly fractional cover, including:
#'     - `"AFG"` (Annual Forb and Grass cover)
#'     - `"PFG"` (Perennial Forb and Grass cover)
#'     - `"SHR"` (Shrub cover)
#'     - `"TRE"` (Tree cover) 
#'     - `"LTR"` (Litter cover)  
#'     - `"BGR"` (Bare Ground cover)
#'
#'   - `"coverMeteorology"` -- the same data provided by `"cover"` above, plus:
#'     - `"annualTemp"` (Annual average temperature in degrees Fahrenheit) 
#'     - `"annualPrecip"` (Annual total precipitation in inches)
#'     
#'   - `"production"` -- annual production, including: 
#'     - `"AFG"` (Annual Forb and Grass production)
#'     - `"PFG"` (Perennial Forb and Grass production) 
#'     - `"HER"` (Herbaceous production)
#'
#'   - `"production16day"` -- 16-day production, including:
#'     - `"date"` (production estimate date)
#'     - `"doy"` (production estimate Julian day of year)
#'     - `"AFG"` (Annual Forb and Grass production)
#'     - `"PFG"` (Perennial Forb and Grass production) 
#'     - `"HER"` (Herbaceous production)
#'
#' @returns  A _data.frame_ with requested time-series data by year or 16-day 
#' production period. In addition to the columns described in Details above, all 
#' products include columns for `"year"` (production estimate year) and 
#' `"feature"` (feature ID, row number from `aoi`). Units are **% cover** for
#' fractional cover and **lbs / acre** for production.
#' 
#' @importFrom utils type.convert
#' @name get_rap_table
#' @export
#' @rdname get_rap_table
#' @examplesIf requireNamespace("terra") && isTRUE(as.logical(Sys.getenv("R_RAPR_EXTENDED_EXAMPLES", unset=FALSE)))
#' aoi <- terra::vect(data.frame(x = -119.72330, y = 36.92204),
#'                    geom = c('x', 'y'),
#'                    crs = "EPSG:4326")
#'
#' # all years (years=NULL) fractional cover data
#' res <- get_rap_table(aoi, product="cover")
#' str(res)
#'
#' # specific year fractional cover and meteorological data 
#' res <- get_rap_table(aoi, years = 1992, product="coverMeteorology")
#' str(res)
#'
#' # multiple specific years above-ground production (annual)
#' res <- get_rap_table(aoi, years = 1993:2003, product="production")
#' str(res)
#'
#' # 1 kilometer buffer around point, above-ground production (16 days) in 2004
#' res <- get_rap_table(terra::buffer(aoi, 1000), years = 2004, product="production16day")
#' str(res)
get_rap_table <- function(aoi, 
                          years = NULL, 
                          product,
                          version = "V3",
                          mask = TRUE, 
                          nodata_flag = NA_real_) {
  
  # Check product & version requested is available 
  product <- match.arg(product,
                       choices = c("cover", "coverMeteorology", "production", "production16day"),
                       several.ok = FALSE)
  
  version <- match.arg(toupper(version),
                       choices = "V3",
                       several.ok = FALSE)
  
  property <- if(product=="coverMeteorology") "cover" else product
  
  # Set the base URL for tabular RAP data API calls
  base_url = "https://us-central1-rap-data-365417.cloudfunctions.net/"
  api_url = paste0(base_url,product,version)
  
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
  if (!is.null(years)) {
    grd <- expand.grid(feature = seq_len(length(geojson_list)), year = years)
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
                            url = api_url,
                            config = httr::content_type_json(),
                            body = json)
    
    content <- httr::content(rap_json, as = "parsed", simplifyVector = TRUE)
    
    if (!is.null(content)) {
      prod <- content$properties[[property]]
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

#' Query RAP 16-day Production Data
#' 
#' `get_rap_production16day_table()` is depreciated, please use 
#' `get_rap_table(product="production16day")` instead.
#' 
#' @param ... allows backward compatibility with `year` argument in depreciated
#' version of `get_rap_production16day_table()`.
#' 
#' @export
#' @rdname get_rap_table
get_rap_production16day_table <- function(aoi, years = NULL, mask = TRUE, nodata_flag = NA_real_, ...) {
  .Deprecated(msg = "`get_rap_production16day_table()` is deprecated.\nPlease use `get_rap_table(product=...)` instead")
  if ("year" %in% names(list(...))) {
    years <- list(...)$year 
  }
  get_rap_table(aoi=aoi,
                years = years,
                product = "production16day", 
                version = "V3", 
                mask = mask, 
                nodata_flag = nodata_flag)
}