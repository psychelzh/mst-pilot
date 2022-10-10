#' Resize Stimuli as Given Size
#'
#' @title
#' @param file Path to stimuli.
#' @param geometry New stimuli size.
#' @return
#' @author Liang Zhang
#' @export
resize_stimuli <- function(file,
                           type = c("face", "object", "place", "word"),
                           geometry = NULL) {
  type <- match.arg(type)
  if (is.null(geometry)) {
    geometry <- geometry_area(300, 300)
  }
  start_id <- as.integer(factor(type, c("face", "object", "place", "word")))
  file_id <- as.integer(regmatches(file, regexpr("\\d+", file))) +
    60 * (start_id - 1)
  file_ver <- fs::path_file(file) |>
    fs::path_ext_remove() |>
    stringr::str_sub(-1)
  img_raw <- image_read(file)
  ext_size <- with(image_info(img_raw), max(width, height))
  img_new <- img_raw |>
    image_convert(format = "jpeg") |>
    image_extent(geometry_area(ext_size, ext_size), color = "white") |>
    image_resize(geometry)
  outfile <- fs::path("stimuli", sprintf("%03d%s.jpg", file_id, file_ver))
  image_write(img_new, outfile)
  outfile
}
