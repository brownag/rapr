### RAP S2 (10 m) data
## Original contribution by Georgia Harrison (April 17, 2025)

## see README file for rangeland-s2 for info about layers and how these data are stored:
## http://rangeland.ntsg.umt.edu/data/rangeland-s2/README

.get_rap_internal <- function(x,
                              years,
                              product,
                              version = NULL,
                              source,
                              filename = NULL,
                              template = NULL,
                              method = "bilinear",
                              datatype = "INT1U",
                              ...,
                              crop = TRUE,
                              mask = TRUE,
                              vrt = FALSE,
                              verbose = TRUE,
                              base_url = ifelse(source == "rap-10m",
                                                yes = "http://rangeland.ntsg.umt.edu/data/rangeland-s2/",
                                                no = "http://rangeland.ntsg.umt.edu/data/rap/")) {

  if (inherits(x, "sf")) {
    x <- terra::vect(x)
  } else if (inherits(x, c('RasterLayer', 'RasterBrick', 'RasterStack'))) {
    x <- terra::rast(x)
  }

  if (inherits(x, 'SpatRaster') && is.null(template)) {
    template <- terra::rast(x)
  }

  if (is.numeric(x)) {
    x <- terra::as.polygons(terra::ext(x[1], x[3], x[4], x[2]), crs = "EPSG:4326")
  } else {
    x <- terra::as.polygons(x, ext = TRUE)
  }

  zones <- .get_utm_zones(x)

  # default grid system for CONUS Albers Equal Area
  # extent limits rounded to units of 5/10/30
  # TODO: helper function for selecting reasonable grid systems
  default_grid <- terra::rast(
    res = ifelse(source == "rap-10m", 10, 30),
    crs =  "EPSG:5070",
    extent = terra::ext(-2356155, 2263815, 270015, 3172635)
  )

  if (isTRUE(template)) {
    .grid <- default_grid
  } else if (is.null(template) || isFALSE(template)) {
    if (length(zones) > 1) {
      message(
        "AOI in multiple UTM zones. ",
        "Result will be projected to a CONUS Albers Equal Area (EPSG:5070) 10 meter grid system. ",
        "Set `template` argument or pass a SpatRaster object as `x` to override."
      )
      .grid <- default_grid
    } else {
      if (source == "rap-10m") {
        .grid <- paste0("EPSG:326", zones)
      } else {
        .grid <- "EPSG:4326"
      }
    }
  # } else if (template == "WGS 84 / Equi7 North America") {
  #   TODO: more standard options for equal-area templates
  } else {
    if (!inherits(template, "SpatRaster")) {
      stop("template should be a SpatRaster object to define the target grid system")
    }
    .grid <- template
  }
  
  if (source == "rap-10m"){
    all_tiles_df <- fetch_tiles_metadata(paste0(base_url, product[1], "/"), years)
  
    # build tile bounding boxes (75x75km with 250m overlap)
    tile_size <- 75000
    tile_overlap <- 250
  
    tiles_grid <- terra::vect(lapply(zones, function(utm) {
      tf <- subset(all_tiles_df, all_tiles_df$utm_zone == utm)
      tf$xmin <- tf$lower_left_x - tile_overlap
      tf$ymin <- tf$lower_left_y - tile_overlap
      tf$xmax <- tf$lower_left_x + tile_size + tile_overlap
      tf$ymax <- tf$lower_left_y + tile_size + tile_overlap
  
      xm <- apply(tf[c("xmin", "xmax", "ymin", "ymax")], MARGIN = 1, function(x) {
        terra::as.polygons(terra::ext(x), crs = paste0("EPSG:326", utm))
      })
      res <- terra::project(x = terra::vect(xm), terra::crs(.grid))
      res <- cbind(res, tf)
    }))
  
    x <- terra::project(x, terra::crs(tiles_grid))
  
    overlapping_tiles <- terra::intersect(tiles_grid, x)
    overlapping_tiles$tile_x = as.integer(gsub(
      ".*(\\d{6})-\\d{7}\\.tif",
      "\\1",
      overlapping_tiles$file_name
    ))
    overlapping_tiles$tile_y = as.integer(gsub(
      ".*\\d{6}-(\\d{7})\\.tif",
      "\\1",
      overlapping_tiles$file_name
    ))
  
    lgrd <- vector("list", length(product))
    for (i in seq_along(product)) {
      lgrd[[i]] <- overlapping_tiles
      lgrd[[i]]$group <- product[i]
    }
    grd <- do.call('rbind', lgrd)
  
    # Construct download URLs for each group/tile/year combo
    grd$url <- paste0(
      base_url,
      grd$group, "/", grd$group, "-",
      grd$year, "-",
      grd$utm_zone, "-",
      sprintf("%06d", grd$tile_x), "-",
      sprintf("%07d", grd$tile_y), ".tif"
    )
  } else {
    grd <- data.frame(
      group = product,
      version = version,
      year = years,
      url = sprintf(
        "%srap-%s/%s/%s-%s-%s.tif",
        base_url, product, version, product, version, years
      )
    )
  }
  
  # TODO: short-circuit for VRT output
  if (isTRUE(vrt)) {
    return(terra::vrt(paste0("/vsicurl/", grd$url), filename = filename, ...))
  }
  
  # Step 8: Download and crop rasters to ROI
  raster_list <- list()

  for (i in seq_len(nrow(grd))) {
    if (verbose) {
     message("Processing: ", grd$url[i])
    }

    raster_data <- terra::rast(paste0("/vsicurl/", grd$url[i]))
   
    if (source == "rap-10m"){
      name <- paste0(grd$group[i], "_",
                     grd$year[i], "_",
                     grd$tile_x[i], "_",
                     grd$tile_y[i])
    } else {
      name <- paste0(grd$group[i], "_",
                     grd$version[i], "_",
                     grd$year[i])
    }
    
    # crop tile to AOI
    raster_crp <- terra::crop(
      raster_data,
      terra::project(x, raster_data), 
      filename = tempfile(
        pattern = paste0("spat_rapr_crp_", name, "_"),
        fileext = ".tif"
      )
    )

    # for multizone AOI or user-specified grid, project and align to target grid system
    if (length(zones) > 1 || !is.null(template)) {
      raster_prj <- terra::project(
        x = raster_crp,
        y = .grid,
        method = method,
        threads = TRUE,
        # align_only to only align with the overlapping portion of target grid
        align_only = TRUE,
        # use_gdal and by_util for faster GDAL-based processing
        use_gdal = TRUE,
        # by_util doesnt work with multisource raster
        by_util = terra::nlyr(raster_crp) == 1,
        # mask needed to remove 0-value artifacts from outside source area
        mask = TRUE,
        filename = tempfile(
          pattern = paste0("spat_rapr_prj_", name, "_"),
          fileext = ".tif"
        )
      )
    } else {
      # otherwise, keep native (WGS84 UTM) system
      raster_prj <- raster_crp
    }
    names(raster_prj) <- names(raster_data)
    raster_list[[name]] <- raster_prj
  }
    
  if (source == "rap-10m") {
      # Merge tiles by group and year
      merged_rasters <- list()
      combo_df <- unique(data.frame(group = grd$group, year = grd$year))
      combo_keys <- paste(combo_df$group, combo_df$year, sep = "_")
    
      for (i in seq_len(nrow(combo_df))) {
        key <- combo_keys[i]
        if (verbose) {
          message("Merging: ", key)
        }
        matched_rasters <- raster_list[grepl(paste0("^", key, "_"), names(raster_list))]
        if (length(matched_rasters) > 1) {
          merged_rasters[[key]] <- terra::merge(terra::sprc(matched_rasters),
                                                ...,
                                                datatype = datatype,
                                                filename = tempfile(
                                                  pattern = paste0("spat_rapr_mrg_", key, "_"),
                                                  fileext = ".tif"
                                                ))
        } else {
          merged_rasters[[key]] <- matched_rasters[[1]]
        }
    
        # set time metadata
        # TODO: units
        nband <- terra::nlyr(merged_rasters[[key]])
        names(merged_rasters[[key]]) <- .get_band_names(combo_df$group[i])
        # terra::longnames(merged_rasters[[key]]) <- paste(rep(combo_df$group[i], nband), names(merged_rasters[[key]]))
        terra::time(merged_rasters[[key]], tstep = "years") <- rep(combo_df$year[i], nband)
      }
  } else {
    for (i in seq_len(nrow(grd))) {
      names(raster_list[[i]]) <- .get_band_names(grd$group[i])
    }
    merged_rasters <- raster_list
  }

  res <- terra::rast(terra::sds(merged_rasters))

  if (isTRUE(crop)) {
    if (verbose) {
      if (is.null(filename)) {
        fn <- "memory or temporary file"
      } else {
        fn <- filename
      }
      message("Cropping and writing result to ", fn)
    }
    
    res <- terra::crop(
      res,
      terra::project(x, res), 
      mask = mask,
      filename = filename,
      datatype = datatype,
      ...
    )
    
  } else if (!is.null(filename)) {
    if (verbose) {
      message("Writing result to ", filename)
    }
    res <- writeRaster(res, filename = filename, datatype = datatype, ...)
  }

  res
}
