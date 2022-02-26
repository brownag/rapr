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
