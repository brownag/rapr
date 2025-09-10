library(tinytest)

is_cran <- function() {
  !interactive() && !isTRUE(as.logical(Sys.getenv("NOT_CRAN", unset = "TRUE")))
}

if (is_cran()) {
  exit_file("On CRAN")
}

# test modern interface
res <- get_rap(
  x = c(-120, 37, -119.99, 36.99),
  product = c("gap", "iag"),
  source = "rap-10m",
  year = 2020:2021,
  verbose = FALSE
)

expect_true(inherits(res, 'SpatRaster'))

expect_equivalent(terra::nlyr(res), 10)

expect_true("iag_2020_invasive_annual_grasses" %in% names(res))

poly <- terra::vect("POLYGON ((-120 36.99,-119.99 37,-120 37,-120 36.99))", crs = "EPSG:4326")
tf <- tempfile(fileext = ".tif")
res <- get_rap(
  poly,
  product = c("vegetation-biomass", "vegetation-cover"),
  version = "v3",
  year = 1986,
  legacy = FALSE,
  verbose = FALSE,
  datatype = "INT2U",
  overwrite = TRUE,
  filename = tf
)

expect_true(file.exists(tf))

expect_true(inherits(res, 'SpatRaster'))

expect_equivalent(terra::nlyr(res), 8)

expect_true("vegetation-cover_v3_1986_perennial_forb_and_grass" %in% names(res))

unlink(tf)

# test 16-day production data tabular interface
res <- get_rap_production16day_table(poly)

expect_equivalent(ncol(res), 7)
expect_equivalent(res[1, 4], NA_real_)
expect_equivalent(colnames(res), c("date", "year", "doy", "AFG", "PFG", "HER", "feature"))

# test legacy interface
res <- get_rap(
  x = c(-120, 37, -119.99, 36.99),
  product = c("vegetation-biomass", "vegetation-cover"),
  source = "rap-30m",
  version = "v3",
  legacy = TRUE,
  year = 2020:2021,
  progress = FALSE
)

expect_true(inherits(res, 'SpatRaster'))

expect_equivalent(terra::nlyr(res), 16)

expect_true("perennial_forb_and_grass_biomass_2021_v3" %in% names(res))

tf <- tempfile(fileext = ".tif")
res <- get_rap(
  terra::vect("POLYGON ((-120 36.99,-119.99 37,-120 37,-120 36.99))", crs = "EPSG:4326"),
  product = c("vegetation-biomass", "vegetation-cover"),
  version = "v3",
  year = 1986,
  legacy = TRUE,
  progress = FALSE,
  filename = tf
)

expect_true(file.exists(tf))

expect_true(inherits(res, 'SpatRaster'))

expect_equivalent(terra::nlyr(res), 8)

expect_true("perennial_forb_and_grass_biomass_1986_v3" %in% names(res))

unlink(tf)

# test legacy sp interface via sf
if (requireNamespace("sf") && requireNamespace("sp", quietly = TRUE)) {
  res <- get_rap(
    sf::as_Spatial(sf::st_as_sf(
      data.frame(
        geometry = sf::st_as_sfc("POLYGON ((-120 36.99,-119.99 37,-120 37,-120 36.99))")
      ), crs = "EPSG:4326"
    )),
    product = c("vegetation-biomass", "vegetation-cover"),
    version = "v3",
    year = 1986,
    legacy = TRUE,
    progress = FALSE
  )

  expect_true(inherits(res, 'SpatRaster'))

  expect_equivalent(terra::nlyr(res), 8)

  expect_true("perennial_forb_and_grass_biomass_1986_v3" %in% names(res))
}
