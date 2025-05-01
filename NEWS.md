# rapr 1.0.0 (development)
* Major `get_rap()` interface updates
 - Added `source` argument to toggle between RAP 30m (`"rap-30m"`; Landsat) and RAP 10m (`"rap-10m"`; Sentinel 2) products
   - For details on new RAP 10m products see: http://rangeland.ntsg.umt.edu/data/rangeland-s2/README and `citation("rapr")`
 - Added `template` argument for setting target grid for projection of result. 
   - Default behavior (`template=NULL`) will return a SpatRaster in the native grid system of requested RAP source.
   - For a large area of interest (that spans multiple UTM zones and `source="rap-10m"`) standard "EPSG:5070" grid system will be used when `template` is not set by the user
 - **Breaking changes**:
    - SpatRaster objects passed as `x` are now used as `template` so that the output conforms with the input grid system. To avoid this behavior either specify `template` or convert the SpatRaster to a polygon extent with `terra::as.polygons(ext=TRUE)` (or similar)
    - Specification of the `product` and `years` arguments is now _required_ (no defaults are set in function definition). This is to encourage users to review the new data sources available, and consider what years and products they want to download.
* Simplified vignette: replaced knitr and rmarkdown with litedown
* Simplified unit testing suite: replaced testthat with tinytest

# rapr 0.1.2 (2024-10-24)
* First tagged GitHub release
* Check that output directory exists before writing output to path specified in `filename (#3)

# rapr 0.1.1
* Updated default arguments to `get_rap()`
* Added a new vignette titled "Accessing Rangeland Analysis Platform (RAP) Data with R"
* Added a `NEWS.md` file to track changes to the package.
