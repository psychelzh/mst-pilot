#' Generate Word Picture
#'
#' @title
#' @param config
#' @return
#' @author Liang Zhang
#' @export
generate_word_pic <- function(config) {
  file_name <- fs::path("origin", "word", sprintf("%03d%s.jpg", config$id, config$ver))
  jpeg(file_name, width = 300, height = 300)
  gplots::textplot(config$word)
  dev.off()
  file_name
}
