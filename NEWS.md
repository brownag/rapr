# rapr 1.1.1 (2025-11-14)
* Fixed handling of empty geometries in `get_rap_production16day_table()` (#15)
* More graceful handling of server-side HTTP errors (#17)

# rapr 1.1.0 (2025-09-10)
* Added `get_rap_production16day_table()` as an interface to the tabular 16-day production API

# rapr 1.0.0 (2025-05-12)
* Initial CRAN release!
* Major `get_rap()` interface updates
  - Added `source` argument to toggle between RAP 30m (`"rap-30m"`; Landsat) and RAP 10m (`"rap-10m"`; Sentinel 2) products
     - For details on new RAP 10m products see: http://rangeland.ntsg.umt.edu/data/rangeland-s2/README and `citation("rapr")`
  - Added `template` argument for setting target grid for projection of result. 
    - Default behavior (`template=NULL`) will return a SpatRaster in the native grid system of requested RAP source.
    - For a large area of interest (that spans multiple UTM zones and `source="rap-10m"`) standard "EPSG:5070" grid system will be used when `template` is not set by the user
  - Added `vrt` argument. When `vrt=TRUE` the merging/resampling process is bypassed and a GDAL VRT file is generated to reference the source directly.
  - Added `legacy` argument. Default (`legacy=FALSE`) behavior is to use GDAL via terra for all raster and vector data processing. Set `legacy=TRUE` to use sf `gdal_translate` implementation from rapr 0.1.x.

### **Breaking changes**
  - Default behavior is to use GDAL via terra for all raster data processing. Set `legacy=TRUE` to use sf `gdal_translate` implementation from rapr 0.1.x.
  - SpatRaster objects passed as `x` are now used as `template` so that the output conforms with the input grid system. To avoid this behavior either specify `template` with the desired grid template, or convert the SpatRaster to a polygon extent with `terra::as.polygons(ext=TRUE)` (or similar)
  - `progress` argument has been replaced with `verbose`; for `legacy=TRUE`
  
### Other changes
* Simplified vignette: replaced knitr and rmarkdown with litedown
* Simplified unit testing suite: replaced testthat with tinytest

# rapr 0.1.2 (2024-10-24)
* First tagged GitHub release
* Check that output directory exists before writing output to path specified in `filename` (#3)

# rapr 0.1.1 (2022-03-21)
* Updated default arguments (`years`, `product`) to `get_rap()`
* Added a new vignette titled "Accessing Rangeland Analysis Platform (RAP) Data with R"
* Added a `NEWS.md` file to track changes to the package.
