# Changelog

## rapr 1.1.1 (2025-11-14)

CRAN release: 2025-11-14

- Fixed handling of empty geometries in
  [`get_rap_production16day_table()`](https://humus.rocks/rapr/reference/get_rap_production16day_table.md)
  ([\#15](https://github.com/brownag/rapr/issues/15),
  [\#16](https://github.com/brownag/rapr/issues/16))
- More graceful handling of server-side HTTP errors
  ([\#14](https://github.com/brownag/rapr/issues/14),
  [\#17](https://github.com/brownag/rapr/issues/17))

## rapr 1.1.0 (2025-09-10)

- Added
  [`get_rap_production16day_table()`](https://humus.rocks/rapr/reference/get_rap_production16day_table.md)
  as an interface to the tabular 16-day production API

## rapr 1.0.0 (2025-05-12)

CRAN release: 2025-05-12

- Initial CRAN release!
- Major [`get_rap()`](https://humus.rocks/rapr/reference/get_rap.md)
  interface updates
  - Added `source` argument to toggle between RAP 30m (`"rap-30m"`;
    Landsat) and RAP 10m (`"rap-10m"`; Sentinel 2) products
    - For details on new RAP 10m products see:
      <http://rangeland.ntsg.umt.edu/data/rangeland-s2/README> and
      `citation("rapr")`
  - Added `template` argument for setting target grid for projection of
    result.
    - Default behavior (`template=NULL`) will return a SpatRaster in the
      native grid system of requested RAP source.
    - For a large area of interest (that spans multiple UTM zones and
      `source="rap-10m"`) standard “EPSG:5070” grid system will be used
      when `template` is not set by the user
  - Added `vrt` argument. When `vrt=TRUE` the merging/resampling process
    is bypassed and a GDAL VRT file is generated to reference the source
    directly.
  - Added `legacy` argument. Default (`legacy=FALSE`) behavior is to use
    GDAL via terra for all raster and vector data processing. Set
    `legacy=TRUE` to use sf `gdal_translate` implementation from rapr
    0.1.x.

#### **Breaking changes**

- Default behavior is to use GDAL via terra for all raster data
  processing. Set `legacy=TRUE` to use sf `gdal_translate`
  implementation from rapr 0.1.x.
- SpatRaster objects passed as `x` are now used as `template` so that
  the output conforms with the input grid system. To avoid this behavior
  either specify `template` with the desired grid template, or convert
  the SpatRaster to a polygon extent with `terra::as.polygons(ext=TRUE)`
  (or similar)
- `progress` argument has been replaced with `verbose`; for
  `legacy=TRUE`

#### Other changes

- Simplified vignette: replaced knitr and rmarkdown with litedown
- Simplified unit testing suite: replaced testthat with tinytest

## rapr 0.1.2 (2024-10-24)

- First tagged GitHub release
- Check that output directory exists before writing output to path
  specified in `filename`
  ([\#3](https://github.com/brownag/rapr/issues/3))

## rapr 0.1.1 (2022-03-21)

- Updated default arguments (`years`, `product`) to
  [`get_rap()`](https://humus.rocks/rapr/reference/get_rap.md)
- Added a new vignette titled “Accessing Rangeland Analysis Platform
  (RAP) Data with R”
- Added a `NEWS.md` file to track changes to the package.
