library(rapr)
library(terra)

p2 <- as.polygons(ext(c(-114.60146, -113.39854, 32.71967, 33.41809)), crs = "OGC:CRS84")
p2 <- crop(p2, y = ext(p2) / 4)
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
  res <- get_rap(
    p2,
    source = "rap-10m",
    product = c("pft", "gap"),
    years = 2023,
    template = equi7na_conus,
    sds = TRUE,
    filename = "yuma-kofa-2023-div4.tif",
    overwrite = TRUE
  )
})
plot(res)

clay05 <- rast("~/Downloads/clay_05.tif")
p4 <- crop(clay05, project(p2, clay05), mask = TRUE)
system.time({
  res <- get_rap(as.polygons(p4, ext = TRUE), source = "rap-10m", product = c("pft", "iag", "pj"), years = 2024,  datatype = "INT1U")
})
plot(res)

system.time({
  res <- get_rap(p4, source = "rap-10m", product = c("pft", "iag", "pj"), years = 2024,  datatype = "INT1U")
})
plot(res)
res

system.time({
  res <- get_rap(p4, source = "rap-30m", product = c("vegetation-cover", "vegetation-npp"), years = 2024,  datatype = "FLT8S")
})
plot(res)
res

system.time({
  res <- get_rap(p4, source = "rap-30m", product = c("vegetation-cover", "vegetation-npp"), years = 2024,  datatype = "INT1U")
})
plot(res)
res
