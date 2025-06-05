#' Select Projection System for RAP Extent
#'
#' This function provides several "standard" projected Coordinate Reference
#' Systems that are suitable for representing Rangeland Analysis Platform
#' products across the contiguous (lower 48) United States at the specified
#' resolution (in meters).
#' @seealso [get_rap()]
#' @details
#'
#' Currently there are three pre-calculated grid systems that have their extent
#' designed to align at 1, 5, 10, 30, 100, and 300 meter resolutions.
#' 
#' `"CONUS_AEA"` is the default template used with `get_rap(source="rap-10m")`
#' when data spanning multiple UTM zones are requested, unless user specifies
#' their own template via SpatRaster object as `x` or `template` argument.
#' 
#' ## Grid Specifications
#' 
#'  - `"CONUS_AEA"`: Albers Equal Area Conic projection for CONUS extent.
#'    - `xmin = -2356300` 
#'    - `ymax = 3172500`
#'    - `xmax = 2264000`
#'    - `ymin = 270000`
#'    - `crs = "EPSG:5070"`
#'  
#'  - `"CONUS_EQUI7`: [Equi7Grid](https://github.com/TUW-GEO/Equi7Grid) projection for CONUS + Hawaii extent.
#'    - `xmin = 599500`
#'    - `ymax = 4967500`
#'    - `xmax = 10737100`
#'    - `ymin = 1913500`
#'    - `crs = "EPSG:27705"`
#'    
#'  - `"CONUS_IGH"`: Interrupted Goode Homolosine projection for CONUS extent.
#'    - `xmin = -13390500`
#'    - `ymax = 5836700`
#'    - `xmax = -8268600` 
#'    - `ymin = 2480600`
#'    - `crs = "+proj=igh"`
#'   
#' @param x _character_. One of `"CONUS_AEA"`, `"CONUS_EQUI7"`, `"CONUS_IGH"`
#' @param res _integer_. Resolution in meters.
#'
#' @returns A _SpatRaster_ object using a standard extent (xmin,ymax,xmax,ymin),
#'   resolution and projected Coordinate Reference System.
#' @export
#'
#' @examples
#' 
#' rap_projection("CONUS_AEA", 10)
#' 
#' rap_projection("CONUS_IGH", 100)
#' 
rap_projection <- function(x, res) {
  switch(toupper(gsub(" ", "_", x)), 
         "CONUS_AEA" =  terra::rast(
           res = res,
           xmin = -2356300, 
           ymax = 3172500,
           xmax = 2264000, 
           ymin = 270000,
           crs = "EPSG:5070"
         ),
         "CONUS_EQUI7" = terra::rast(
           res = res,
           xmin = 599500,
           ymax = 4967500,
           xmax = 10737100,
           ymin = 1913500,
           crs = "EPSG:27705"
         ),
         "CONUS_IGH" = terra::rast(
           res = res, 
           xmin = -13390500, 
           ymax = 5836700,
           xmax = -8268600, 
           ymin = 2480600,
           crs = "+proj=igh"
         ),
         stop("Unknown projection identifier, choose one of: CONUS_AEA, CONUS_EQUI7, CONUS_IGH or specify your own custom `template` argument"))
}