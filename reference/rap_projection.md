# Select Projection System for RAP Extent

This function provides several "standard" projected Coordinate Reference
Systems that are suitable for representing Rangeland Analysis Platform
products across the contiguous (lower 48) United States at the specified
resolution (in meters).

## Usage

``` r
rap_projection(x, res)
```

## Arguments

- x:

  *character*. One of `"CONUS_AEA"`, `"CONUS_EQUI7"`, `"CONUS_IGH"`

- res:

  *integer*. Resolution in meters.

## Value

An empty *SpatRaster* object with a standard extent
(xmin,ymax,xmax,ymin), resolution and projected Coordinate Reference
System.

## Details

Currently there are three pre-calculated grid systems that have their
extent designed to align at 1, 5, 10, 30, 100, and 300 meter
resolutions.

`"CONUS_AEA"` is the default template used with
`get_rap(source="rap-10m")` when data spanning multiple UTM zones are
requested, unless user specifies their own template via SpatRaster
object as `x` or `template` argument.

### Grid Specifications

- `"CONUS_AEA"`: Albers Equal Area Conic projection for CONUS extent.

  - `xmin = -2356300`

  - `ymax = 3172500`

  - `xmax = 2264000`

  - `ymin = 270000`

  - `crs = "EPSG:5070"`

- `"CONUS_EQUI7`: [Equi7Grid](https://github.com/TUW-GEO/Equi7Grid)
  projection for CONUS + Hawaii extent.

  - `xmin = 599500`

  - `ymax = 4967500`

  - `xmax = 10737100`

  - `ymin = 1913500`

  - `crs = "EPSG:27705"`

- `"CONUS_IGH"`: Interrupted Goode Homolosine projection for CONUS
  extent.

  - `xmin = -13390500`

  - `ymax = 5836700`

  - `xmax = -8268600`

  - `ymin = 2480600`

  - `crs = "+proj=igh"`

## See also

[`get_rap()`](https://humus.rocks/rapr/reference/get_rap.md)

## Examples

``` r
rap_projection("CONUS_AEA", 10)
#> class       : SpatRaster 
#> size        : 290250, 462030, 1  (nrow, ncol, nlyr)
#> resolution  : 10, 10  (x, y)
#> extent      : -2356300, 2264000, 270000, 3172500  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Conus Albers (EPSG:5070) 

rap_projection("CONUS_IGH", 100)
#> class       : SpatRaster 
#> size        : 33561, 51219, 1  (nrow, ncol, nlyr)
#> resolution  : 100, 100  (x, y)
#> extent      : -13390500, -8268600, 2480600, 5836700  (xmin, xmax, ymin, ymax)
#> coord. ref. : +proj=igh +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs 
```
