# Query RAP 16-day Production Data

Retrieves remotely sensed production estimates from the Rangeland
Analysis Platform (RAP) using the `production16dayV3` API endpoint. This
function supports querying one or more spatial features (points, lines,
or polygons) provided as a `terra` `SpatVector` in WGS84 longitude
latitude (`"EPSG:4326"`).

## Usage

``` r
get_rap_production16day_table(
  aoi,
  year = NULL,
  mask = TRUE,
  nodata_flag = NA_real_
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

- year:

  integer. Optional. Numeric year or vector of years (1986 to last full
  year). Default: `NULL` returns all available years.

- mask:

  logical. Exclude cropland, development, and water? Default: `TRUE`.

- nodata_flag:

  numeric. Value to use for missing data. The API encodes "NODATA" as
  `-99`. Default: `NA_real_` replaces `-99` with `NA`.

## Value

A data.frame with 16-day production data including the following
columns: `"date"` (production estimate date), `"year"` (production
estimate year), `"doy"` (production estimate Julian day of year),
`"AFG"` (Annual Forb and Grass production), `"PFG"` (Perennial Forb and
Grass production), `"HER"` (Herbaceous production), `"feature"` (feature
ID, row number from `aoi`)

## Details

For each feature - year combination, a separate request is made to the
RAP API, and results are returned as a combined `data.frame`. In the
special case of `year=NULL`) default all available years are returned in
a single query.

For more information on the API and data products, see the RAP API
documentation: <https://rangelands.app/support/71-api-documentation>

## Examples

``` r
aoi <- terra::vect(data.frame(x = -119.72330, y = 36.92204),
                   geom = c('x', 'y'),
                   crs = "EPSG:4326")

# all years (year=NULL)
res <- get_rap_production16day_table(aoi)
str(res)
#> 'data.frame':    920 obs. of  7 variables:
#>  $ date   : chr  "1986-01-16" "1986-02-01" "1986-02-17" "1986-03-05" ...
#>  $ year   : num  1986 1986 1986 1986 1986 ...
#>  $ doy    : num  16 32 48 64 80 96 112 128 144 160 ...
#>  $ AFG    : num  87.4 113.9 117.9 195.7 146.8 ...
#>  $ PFG    : num  1.6 4.01 3.21 4.81 2.41 ...
#>  $ HER    : num  89 118 121 201 149 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...

# specific year
res <- get_rap_production16day_table(aoi, year = 1992)
str(res)
#> 'data.frame':    23 obs. of  7 variables:
#>  $ date   : chr  "1992-01-16" "1992-02-01" "1992-02-17" "1992-03-04" ...
#>  $ year   : num  1992 1992 1992 1992 1992 ...
#>  $ doy    : num  16 32 48 64 80 96 112 128 144 160 ...
#>  $ AFG    : num  41.9 50 67.8 140.4 169.4 ...
#>  $ PFG    : num  0 3.23 8.07 20.97 25.81 ...
#>  $ HER    : num  41.9 53.2 75.8 161.3 195.2 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...

# multiple specific years
res <- get_rap_production16day_table(aoi, year = 1993:2003)
str(res)
#> 'data.frame':    253 obs. of  7 variables:
#>  $ date   : chr  "1993-01-16" "1993-02-01" "1993-02-17" "1993-03-05" ...
#>  $ year   : num  1993 1993 1993 1993 1993 ...
#>  $ doy    : num  16 32 48 64 80 96 112 128 144 160 ...
#>  $ AFG    : num  29.1 63.8 92.2 113.4 187.5 ...
#>  $ PFG    : num  0 1.58 1.58 3.15 5.51 ...
#>  $ HER    : num  29.1 65.4 93.7 116.6 193 ...
#>  $ feature: num  1 1 1 1 1 1 1 1 1 1 ...

# 1 kilometer buffer around point
res <- get_rap_production16day_table(terra::buffer(aoi, 1000), year = 2004)
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
