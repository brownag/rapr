library(rapr)
library(terra)

p2 <- as.polygons(ext(c(-114.60146, -113.39854, 32.71967, 33.41809)), crs = "OGC:CRS84")
p2 <- crop(p2, y = ext(p2))
plet(p2)

# target template grid system
equi7na_conus <- rast(
  res = 30,
  xmin = 5995440,
  ymin = 1913880,
  xmax = 10736640,
  ymax = 4967310,
  crs = "EPSG:27705"
)
res(equi7na_conus) <- 10

system.time({
  res <- get_rap_10m(p2, years = 2023, template = equi7na_conus, filename = "yuma-kofa-2023.tif")
})
plot(res)

clay05 <- rast("~/Downloads/clay_05.tif")
p4 <- crop(clay05, project(p2, clay05), mask = TRUE)
system.time({
  res <- get_rap_10m(as.polygons(p4, ext = TRUE), years = 2024,  datatype = "INT1U")
})
plot(res)
