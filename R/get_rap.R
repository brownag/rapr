#' Get Rangeland Analysis Platform (RAP) Grids
#'
#' Two sets of Rangeland Analysis Platform products are available (see `source`
#' argument). `"rap-30m"` is Landsat-derived and has approximately 30 meter
#' resolution in WGS84 decimal degrees (`"EPSG:4326"`). This is the data source
#' that has been used in the rapr package since 2022. A newer source (2025),
#' `"rap-10m"`, is Sentinel 2-derived and has 10 meter resolution in the local
#' WGS84 UTM zone (`"EPSG:326XX"`, where XX is the two digit UTM zone number).
#' See Details for the products and bands available for the different
#' resolutions and sources. 
#'
#' @param x Target extent. Derived from an sf, terra, raster or sp object or
#'   numeric vector containing `xmin`, `ymax`, `xmax`, `ymin` in WGS84 decimal
#'   degrees (longitude/latitude, `"EPSG:4326"`).
#' @param years _integer_. Year(s) to query. Products are available from 1986
#'   (`source="rap-30m"`) or 2018 (`source="rap-10m"`) up to the year prior to
#'   the current year, based on availability of the Landsat and Sentinel 2
#'   source data.
#' @param product Target data: `"vegetation-biomass"`, `"vegetation-cover"`,
#'   and/or `"vegetation-npp"` for `source="rap-30m"`; `"pft"` (plant functional
#'   type cover), `"gap"` (canopy gap), `"arte"` (Artemisia spp. cover), `"iag"`
#'   (invasive annual grass cover), or `"pj"` (pinyon juniper cover) for
#'   `source="rap-10m"`.
#' @param filename Output filename (optional; default stores in temporary file
#'   or in memory, see `terra::tmpFiles()`)
#' @param ... Additional arguments passed to internal query function and
#'   [terra::writeRaster()] (or [terra::vrt()] when `vrt=TRUE`)
#' @param source Grid sources. Options include `"rap-30m"` (default; Landsat)
#'   and `"rap-10m"` (Sentinel 2).
#' @param version Target version: `"v3"` and/or `"v2"` (for `"rap-30m"`).
#'   Currently ignored for `source="rap-10m"`.
#' @param vrt _logical_. Short circuit to return Virtual Raster Dataset (VRT)
#'   for selected grids via [terra::vrt()]. Default: `FALSE`. Note:
#'   `gdalbuildvrt` does not support heterogeneous projection systems, so this
#'   option is not compatible with `source="rap-10m"` over multiple UTM zone
#'   areas of interest.
#' @param sds _logical_. Return data as a SpatRasterDataset? Helpful for results
#'   containing multiple years and products. Default `FALSE` returns a
#'   SpatRaster object.
#' @param legacy _logical_. Use legacy (gdal_translate) method? Default: `TRUE`
#'   (applies only to `source="rap-30m"`).
#' @param verbose logical. Print messages indicating progress? Default: `TRUE`.
#'   For `legacy=TRUE` progress is shown using [utils::txtProgressBar()].
#' @details
#' 
#' ## Sources, Products, and Band Information
#'
#' For `"rap-30m"` you can query several Landsat derived annual biomass,
#' cover, and Net Primary Productivity products from 1986 to present:
#'
#'   - `product = "vegetation-biomass"` returns [two layers](http://rangeland.ntsg.umt.edu/data/rap/rap-vegetation-biomass/v3/README) per year:
#'
#'     - 2 Bands:`"annual forb and grass"`, `"perennial forb and grass"` (**lbs / acre**)
#'
#'   - `product = "vegetation-cover"` returns [six layers](http://rangeland.ntsg.umt.edu/data/rap/rap-vegetation-cover/v3/README) per year:
#'
#'     - 6 Bands: `"annual forb and grass"`, `"bare ground"`, `"litter"`, `"perennial forb and grass"`, `"shrub"`, `"tree"` (**% cover**)
#'
#'   - `product = "vegetation-npp"` returns [four layers](http://rangeland.ntsg.umt.edu/data/rap/rap-vegetation-npp/v3/README) per year:
#'
#'     - 4 Bands: `"annual forb and grass"`, `"perennial forb and grass"`, `"shrub"`, `"tree"` (NPP; kg*C/m^2)
#'
#' For `"rap-10m"` you can query several [Sentinel 2 derived cover
#' products](http://rangeland.ntsg.umt.edu/data/rangeland-s2/README) at 10 meter
#' resolution from 2018 to present:
#'
#'    - `product = "pft"` returns fractional cover estimates of plant functional types:
#'
#'      - 6 Bands: `"annual forb and grass"`, `"bare ground"`, `"litter"`, `"perennial forb and grass"`, `"shrub"`, `"tree"`  (**% cover**)
#'
#'    - `product = "gap"` returns canopy gap estimates for four canopy gap size classes:
#'
#'      - 4 Bands: `"Gaps 25-50 cm"`, `"Gaps 51-100 cm"`, `"Gaps 100-200 cm"`, `"Gaps >200 cm"`  (**% cover**)
#'
#'    - `product = "arte"` returns cover estimates of Artemisia species, including A. arbuscula, A. cana, A. nova, A. tridentata, and A. tripartita.
#'
#'      - 1 Band: `"Artemisia spp."` (**% cover**)
#'
#'    - `product = "iag"` returns fractional cover estimates of Bromus tectorum, B. arvensis, B. rubens, B. hordeaceus, Eremopyrum triticeum, Schismus spp., Taeniatherum caput-medusae, and Ventenata dubia.
#'
#'      - 1 Band: `"invasive annual grass"` (**% cover**)
#'
#'    - `product = "pj"` returns fractional cover estimates of Juniperus monosperma, J. occidentalis, J. osteosperma, J. scopulorum, Pinus edulis, and P. monophylla.
#'
#'      - 1 Band: `"pinyon-juniper"` (**% cover**)
#'
#' ## Temporary Files
#'
#'   Large requests may generate intermediate objects that will be stored as
#'   temporary files. See [terra::tmpFiles()] to view the file paths. These
#'   files will be removed when an **R** session ends.
#'
#' ## Alternate Specification of Area of Interest
#'
#'   In lieu of a spatial object from \{terra\}, \{raster\}, \{sf\} or \{sp\}
#'   packages you may specify a bounding box using a numeric vector containing
#'   the top-left and bottom-right coordinates (`xmin`, `ymax`, `xmax`, `ymin`)
#'   in WGS84 longitude/latitude decimal degrees. This corresponds to the
#'   conventional order used in the `gdal_translate` `-projwin` option. e.g.
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
#' ## Native Resolution and Projection Systems
#'
#'   Native cell resolution of `"rap-30m"` is approximately 30m x 30m in WGS84
#'   geographic coordinate system (longitude, latitude). Native cell resolution of
#'   `"rap-10m"` is 10m x 10m in the local (projected) WGS84 Universal Transverse
#'   Mercator (UTM) system.
#'
#'   For `"rap-10m"` requests spanning _multiple_ UTM zones, either pass a
#'   _SpatRaster_ object as `x` or specify `template` argument. In lieu of a
#'   user-specified grid system for multi-zone requests, a default CONUS Albers
#'   Equal Area projection (`"EPSG:5070"`) with 10 m resolution will be used.
#'
#' @return a _SpatRaster_ containing the requested product layers by year. If
#'   `sds=TRUE` a SpatRasterDataset where each SpatRaster contains only one
#'   product (possibly with multiple years)
#' 
#' @references See `citation("rapr")` for all references related to Rangeland
#'   Analysis Platform products.
#'
#' @export
get_rap <- function(x,
                    years,
                    product,
                    filename = NULL,
                    ...,
                    source = "rap-30m",
                    version = "v3",
                    vrt = FALSE,
                    sds = FALSE,
                    legacy = FALSE,
                    verbose = TRUE) {

  source <- match.arg(tolower(source), choices = c("rap-30m", "rap-10m"))

  overwrite <- list(...)[["overwrite"]]
  if ((is.null(overwrite) || isFALSE(overwrite)) && 
       (!is.null(filename) && file.exists(filename))) {
    stop("File '", filename, "' exists. You can use 'overwrite=TRUE' to overwrite it.", call. = FALSE)
  }
  
  if (source == "rap-10m") {
    # RAP 10m through new interface

    # version currently ignored for RAP 10m data
    valid_years <- 2018:(as.integer(format(Sys.Date(), "%Y")) - 1)
    if (!all(years %in% valid_years)) {
      stop("Invalid years provided. Acceptable years are from 2018 to ",
           current_year - 1)
    }

    product <- match.arg(
      tolower(product),
      choices = c("pft", "gap", "arte", "iag", "pj"),
      several.ok = TRUE
    )
    
    .get_rap_internal(
      x,
      years = years,
      source = source,
      product = product,
      filename = filename,
      vrt = vrt,
      sds = sds,
      ...,
      verbose = verbose
    )
  } else if (source == "rap-30m") {
    version <- match.arg(tolower(version),
                         choices = c("v3", "v2"),
                         several.ok = TRUE)
    
    product <- match.arg(
      tolower(product),
      choices = c("vegetation-biomass", "vegetation-cover", "vegetation-npp"),
      several.ok = TRUE
    )
    
    if (isFALSE(legacy)) {
      # RAP 30m through new interface
      .get_rap_internal(
        x,
        years = years,
        source = source,
        version = version,
        product = product,
        filename = filename,
        vrt = vrt,
        sds = sds,
        ...,
        verbose = verbose
      )
    } else if (isTRUE(legacy)) {
      # RAP 30m through old interface
      .get_rap_30m_legacy(
        x,
        years = years,
        product = product,
        filename = filename,
        version = version,
        progress = verbose
      )
    } else {
      stop("`legacy` argument must be TRUE or FALSE", call. = FALSE)
    }
  }
}
