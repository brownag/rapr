#############################################################################
###### PULLING RAP S2 (10 m) data
## Georgia Harrison
## April 17, 2025

## designed to be an extension of the rapr packge
## accessing the rangeland analysis platform data in R
# https://humus.rocks/rapr/


## see README file for rangeland-s2 for info about layers and how these data are stores:
## http://rangeland.ntsg.umt.edu/data/rangeland-s2/README


## overview
############################################################
######## prep steps::
##### bring in a region of interest (shapefile)
##### for that ROI, determine the UTM zone
##### pull a lookup table for the RAP coordinates, filter to UTM zone of interest
##### determine which tile(s) overlap with the ROI.
##### save the UTM zone, and coordinates for the ROI tiles for pulling to build the URL


###### Pull the RAP 10 m data
#### users specify which years and groups are desired
#### use the UTM zone, and coordinates for the ROI tiles for pulling along with that info to detremine the URLS to pull
### read in those urls as rasters
#### for each group, create a seperate raster stack. use the band names x years as layers
### this is the result. users could crop (BUT NOT MASK) to the ROI

########################################################################################

# Main function to fetch and process RAP S2 data for a given ROI, groups, and years
get_rap_10m <- function(roi, groups, years) {
  message("Starting RAP S2 data retrieval...")

  # Step 0: Validate inputs
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  valid_years <- 2018:(current_year - 1)
  valid_groups <- c("pft", "gap", "arte", "iag", "pj")

  if (any(!years %in% valid_years)) {
    stop("Invalid years provided. Acceptable years are from 2018 to ", current_year - 1)
  }

  if (any(!groups %in% valid_groups)) {
    stop("Invalid groups provided. Acceptable groups are: ", paste(valid_groups, collapse = ", "))
  }

  # Step 1: Convert SpatVector to sf if needed
  if (inherits(roi, "SpatVector")) {
    roi <- sf::st_as_sf(roi)
  }

  # Always use bounding box of input ROI (regardless of number of features or geometry type)
  roi_bbox <- sf::st_sf(sf::st_as_sfc(sf::st_bbox(roi)), crs = st_crs(roi))
  roi <- roi_bbox

  # Step 2: Determine UTM zone from ROI
  roi_utm_zone <- get_utm_zone(roi)
  message(paste("UTM Zone:", roi_utm_zone))

  # Step 3: Collect tile metadata using the first group (tile locations are shared across groups)
  message(paste("Fetching tile metadata from group:", groups[1]))
  base_url <- paste0("http://rangeland.ntsg.umt.edu/data/rangeland-s2/", groups[1], "/")
  all_tiles_df <- fetch_tiles_metadata(base_url, years)

  # Step 4: Filter metadata to match ROI's UTM zone
  tiles_filtered <- subset(all_tiles_df, utm_zone == roi_utm_zone)

  # Step 5: Build tile bounding boxes (75x75km with 250m overlap)
  tile_size <- 75000
  tile_overlap <- 250
  tiles_filtered <-  dplyr::mutate(
    tiles_filtered,
    geometry = purrr::pmap(list(lower_left_x, lower_left_y),
      function(x, y) {
        x_min <- x - tile_overlap
        y_min <- y - tile_overlap
        x_max <- x + tile_size + tile_overlap
        y_max <- y + tile_size + tile_overlap
        sf::st_polygon(list(matrix(
          c(
            x_min,
            y_min,
            x_max,
            y_min,
            x_max,
            y_max,
            x_min,
            y_max,
            x_min,
            y_min
          ),
          ncol = 2,
          byrow = TRUE
        )))
      })
  )

  tiles_grid <- sf::st_as_sf(tiles_filtered, crs = 32600 + roi_utm_zone)

  # Step 6: Reproject ROI and find overlapping tiles
  roi <- sf::st_transform(roi, sf::st_crs(tiles_grid))
  overlapping_tiles <- tiles_grid[sf::st_intersects(tiles_grid, roi, sparse = FALSE), ]
  overlapping_tiles <- transform(
    overlapping_tiles,
    tile_x = as.numeric(stringr::str_extract(file_name, "\\d{6}(?=-\\d{7}\\.tif)")),
    tile_y = as.numeric(stringr::str_extract(file_name, "\\d{7}(?=\\.tif)"))
  )
  message("Found overlapping tiles:")
  print(dplyr::distinct(overlapping_tiles, tile_x, tile_y))

  # Step 7: Construct download URLs for each group/tile/year combo
  urls <- transform(
    unique(
      expand.grid(
        group = groups,
        tile_x = overlapping_tiles$tile_x,
        tile_y = overlapping_tiles$tile_y,
        year = years
      ),
    ),
    url = paste0(
      "http://rangeland.ntsg.umt.edu/data/rangeland-s2/",
      group,
      "/",
      group,
      "-",
      year,
      "-",
      roi_utm_zone,
      "-",
      sprintf("%06d", tile_x),
      "-",
      sprintf("%07d", tile_y),
      ".tif"
    )
  )

  message("Generated download URLs:")
  print(urls)

  # Step 8: Download and crop rasters to ROI
  message("Downloading and processing rasters...")
  raster_list <- list()
  roi_proj <- sf::st_transform(roi, crs = 32600 + roi_utm_zone)

  for (i in seq_len(nrow(urls))) {
    message(paste("Processing:", urls$url[i]))
    raster_data <- terra::rast(paste0("/vsicurl/", urls$url[i]))
    raster_cropped <- terra::crop(raster_data, roi_proj)
    name <- paste0(urls$group[i], "_", urls$year[i], "_", urls$tile_x[i], "_", urls$tile_y[i])
    raster_list[[name]] <- raster_cropped
  }

  # Step 9: Merge tiles by group and year
  merged_rasters <- list()
  combo_keys <- unique(paste(urls$group, urls$year, sep = "_"))
  for (key in combo_keys) {
    matched_rasters <- raster_list[grepl(paste0("^", key, "_"), names(raster_list))]
    if (length(matched_rasters) > 1) {
      merged_rasters[[key]] <- do.call(merge, unname(matched_rasters))
    } else {
      merged_rasters[[key]] <- matched_rasters[[1]]
    }
  }

  return(merged_rasters)
}

# Helper function to fetch and parse tile metadata from the server
fetch_tiles_metadata <- function(base_url, years) {
  response <- httr::GET(base_url)
  content <- httr::content(response, "text")
  file_names <- stringr::str_extract_all(content, "\\w+-\\d{4}-\\d{2}-\\d{6}-\\d{7}\\.tif")[[1]]
  coords <- stringr::str_match(file_names,
                               "(\\w+)-(\\d{4})-(\\d{2})-(\\d{6})-(\\d{7})\\.tif")
  subset(
    data.frame(
      file_name = file_names,
      group = coords[, 2],
      year = as.numeric(coords[, 3]),
      utm_zone = as.numeric(coords[, 4]),
      lower_left_x = as.numeric(coords[, 5]),
      lower_left_y = as.numeric(coords[, 6]),
      stringsAsFactors = FALSE
    ),
    year %in% years
  )
}

# Helper function to determine the UTM zone of an ROI
get_utm_zone <- function(roi) {
  roi_wgs84 <- sf::st_transform(roi, 4326)
  lon <- sf::st_coordinates(sf::st_centroid(roi_wgs84))[, 1]
  floor((lon + 180) / 6) + 1
}

# Example usage:
# roi <- st_read("path_to_shapefile.shp")
# rap_rasters <- get_rap_10m(roi, groups = c("pft", "pj"), years = c(2021, 2022))
