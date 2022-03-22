test_that("get_rap works", {
  
  skip_if_offline()
  
  skip_on_cran()
  
  res <- get_rap(
    # x = wk::rct(xmin = -120,    ymax = 37, 
    #             xmax = -119.99, ymin = 36.99, crs = 4326), 
    x = c(-120, 37, -119.99, 36.99), 
    version = "v3",
    year = 2020:2021
  )
  
  expect_true(inherits(res, 'SpatRaster'))
  
  expect_equal(terra::nlyr(res), 16)
  
  expect_true("perennial_forb_and_grass_biomass_2021_v3" %in% names(res))
})

test_that("get_rap spatial object interface and writing to file", {
  
  skip_if_offline()
  
  skip_on_cran()
  
  tf <- tempfile(fileext = ".tif")
  res <- get_rap(
    terra::vect("POLYGON ((-120 36.99,-119.99 37,-120 37,-120 36.99))", crs = "EPSG:4326"), 
    version = "v3",
    year = 1986,
    progress = FALSE,
    filename = tf
  )
  
  expect_true(file.exists(tf))
  
  expect_true(inherits(res, 'SpatRaster'))
  
  expect_equal(terra::nlyr(res), 8)
  
  expect_true("perennial_forb_and_grass_biomass_1986_v3" %in% names(res))
  
  unlink(tf)
})

test_that("get_rap sf and legacy sp interface", {
  
  skip_if_offline()
  
  skip_on_cran()
  
  res <- get_rap(
    sf::as_Spatial(sf::st_as_sf(data.frame(
      geometry = st_as_sfc("POLYGON ((-120 36.99,-119.99 37,-120 37,-120 36.99))")
    ), crs = "EPSG:4326")), 
    version = "v3",
    year = 1986
  )
  
  expect_true(inherits(res, 'SpatRaster'))
  
  expect_equal(terra::nlyr(res), 8)
  
  expect_true("perennial_forb_and_grass_biomass_1986_v3" %in% names(res))
  
})