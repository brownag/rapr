#' Get Rangeland Analysis Platform (RAP) Grids
#'
#' @param x Target extent. Derived from an sf, terra or sp object or numeric vector containing xmin, ymax, xmax, ymin in WGS84 latitude/longitude decimal degrees.
#' @param years integer. Year(s) to query
#' @param filename Output filename
#' @param dataset Target data: either `"vegetation-biomass"` or `"vegetation-cover"`
#' @param version Target version: either `"v3"` or `"v2"`
#' @importFrom terra rast
#' @export
get_rap <- function(x,
                    years = 1986:2021,
                    filename,
                    dataset = c("vegetation-biomass", "vegetation-cover"),
                    version = c("v3", "v2")) {
  terra::rast(
    lapply(years, function (y)
      .get_rap_year(
        x = x,
        year = y,
        dataset = dataset,
        version = version
      ))
  )
}

.gdal_utils_opts <- function(lst) do.call('c', lapply(names(lst), function(y) c(y, lst[[y]])))

#' @importFrom sf gdal_utils
#' @importFrom terra rast
.get_rap_year <- function(x,
                          year,
                          filename = tempfile(fileext = '.tif'),
                          dataset,
                          version = c("v3", "v2")) {
  uri <- sprintf("/vsicurl/http://rangeland.ntsg.umt.edu/data/rap/rap-%s/%s/%s-%s-%s.tif",
                 dataset, version, dataset, version, year)
  sf::gdal_utils("translate",
                 source = uri,
                 options = .gdal_utils_opts(list(
                   "-co" = "compress=lzw",
                   "-co" = "tiled=yes",
                   "-co" = "bigtiff=yes",
                   "-projwin" = x
                 )),
                 destination = filename)
  terra::rast(filename)
}
