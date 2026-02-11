# Query RAP Tabular Data

Retrieves remotely sensed production or cover estimates from the
Rangeland Analysis Platform (RAP) using the tabular data API endpoints.
This function supports querying one or more spatial features (points,
lines, or polygons) provided as a `terra` `SpatVector` object, or any
spatial object that can be converted with
[`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html).
See Details for the products available.

`get_rap_production16day_table()` is depreciated, please use
`get_rap_table(product="production16day")` instead.

## Usage

``` r
get_rap_table(
  aoi,
  years = NULL,
  product,
  version = "V3",
  mask = TRUE,
  nodata_flag = NA_real_
)

get_rap_production16day_table(
  aoi,
  years = NULL,
  mask = TRUE,
  nodata_flag = NA_real_,
  ...
)
```

## Arguments

- aoi:

  Area of Interest. A `SpatVector` object, or any spatial object that
  can be converted with
  [`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html).
  The AOI coordinates will be transformed to WGS84 longitude latitude
  (`"EPSG:4326"`). The AOI can be specified using point, line and
  polygon geometries. Each unique feature will be passed separately to
  the API. The result `feature` column contains the row index of the
  input feature from `aoi`.

- years:

  integer. Optional. Numeric year or vector of years (1986 to last full
  year). Default: `NULL` returns all available years.

- product:

  Target data: `"cover"`, `"coverMeteorology"`, `"production"`, or
  `"production16day"`.

- version:

  Target version: `"V3"`.

- mask:

  logical. Exclude cropland, development, and water? Default: `TRUE`.

- nodata_flag:

  numeric. Value to use for missing data. The API encodes "NODATA" as
  `-99`. Default: `NA_real_` replaces `-99` with `NA`.

- ...:

  allows backward compatibility with `year` argument in depreciated
  version of `get_rap_production16day_table()`.

## Value

A *data.frame* with requested time-series data by year or 16-day
production period. In addition to the columns described in Details
above, all products include columns for `"year"` (production estimate
year) and `"feature"` (feature ID, row number from `aoi`). Units are **%
cover** for fractional cover and **lbs / acre** for production.

## Details

For each feature - year combination, a separate request is made to the
RAP API, and results are returned as a combined `data.frame`. In the
special case of (`years=NULL`) default, all available years are returned
in a single query.

For more information on the API and data products, see the RAP API
documentation: <https://rangelands.app/support/71-api-documentation>

### Products Overview

You can query several Landsat derived biomass, cover, and meteorological
products from 1986 to present:

- `"cover"` – yearly fractional cover, including:

  - `"AFG"` (Annual Forb and Grass cover)

  - `"PFG"` (Perennial Forb and Grass cover)

  - `"SHR"` (Shrub cover)

  - `"TRE"` (Tree cover)

  - `"LTR"` (Litter cover)

  - `"BGR"` (Bare Ground cover)

- `"coverMeteorology"` – the same data provided by `"cover"` above,
  plus:

  - `"annualTemp"` (Annual average temperature in degrees Fahrenheit)

  - `"annualPrecip"` (Annual total precipitation in inches)

- `"production"` – annual production, including:

  - `"AFG"` (Annual Forb and Grass production)

  - `"PFG"` (Perennial Forb and Grass production)

  - `"HER"` (Herbaceous production)

- `"production16day"` – 16-day production, including:

  - `"date"` (production estimate date)

  - `"doy"` (production estimate Julian day of year)

  - `"AFG"` (Annual Forb and Grass production)

  - `"PFG"` (Perennial Forb and Grass production)

  - `"HER"` (Herbaceous production)

## Examples

``` r
aoi <- terra::vect(data.frame(x = -119.72330, y = 36.92204),
                   geom = c('x', 'y'),
                   crs = "EPSG:4326")

# all years (years=NULL) fractional cover data
res <- get_rap_table(aoi, product="cover")
str(res)
#> 'data.frame':    40 obs. of  8 variables:
#>  $ year   : num  1986 1987 1988 1989 1990 ...
#>  $ AFG    : num  68 77 78 71 71 71 57 61 65 65 ...
#>  $ PFG    : num  4 2 9 11 13 18 14 3 13 10 ...
#>  $ SHR    : num  3 2 3 3 0 0 1 3 2 5 ...
#>  $ TRE    : num  1 0 0 1 0 0 1 1 1 0 ...
#>  $ LTR    : num  16 17 13 12 15 10 19 19 14 13 ...
#>  $ BGR    : num  6 5 0 2 2 1 9 8 3 4 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...

# specific year fractional cover and meteorological data 
res <- get_rap_table(aoi, years = 1992, product="coverMeteorology")
str(res)
#> 'data.frame':    1 obs. of  10 variables:
#>  $ year        : num 1992
#>  $ AFG         : num 57
#>  $ PFG         : num 14
#>  $ SHR         : num 1
#>  $ TRE         : num 1
#>  $ LTR         : num 19
#>  $ BGR         : num 9
#>  $ annualTemp  : num 64.5
#>  $ annualPrecip: num 14.1
#>  $ feature     : num 1

# multiple specific years above-ground production (annual)
res <- get_rap_table(aoi, years = 1993:2003, product="production")
str(res)
#> 'data.frame':    11 obs. of  5 variables:
#>  $ year   : num  1993 1994 1995 1996 1997 ...
#>  $ AFG    : num  1723 1631 1898 1829 791 ...
#>  $ PFG    : num  75.6 252.5 321.4 83.4 0 ...
#>  $ HER    : num  1799 1884 2220 1912 791 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...

# 1 kilometer buffer around point, above-ground production (16 days) in 2004
res <- get_rap_table(terra::buffer(aoi, 1000), years = 2004, product="production16day")
str(res)
#> 'data.frame':    23 obs. of  7 variables:
#>  $ date   : chr  "2004-01-16" "2004-02-01" "2004-02-17" "2004-03-04" ...
#>  $ year   : num  2004 2004 2004 2004 2004 ...
#>  $ doy    : num  16 32 48 64 80 96 112 128 144 160 ...
#>  $ AFG    : num  48.1 62.9 102.8 124.2 233.4 ...
#>  $ PFG    : num  2.46 2.96 4.75 5.48 10.99 ...
#>  $ HER    : num  50.5 65.9 107.6 129.7 244.3 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...
```
