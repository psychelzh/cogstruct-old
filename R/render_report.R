#' Render report
#'
#' @title
#' @param input
#' @param output_dir
#' @param output_file
#' @param ...
#' @return
#' @author Liang Zhang
#' @export
render_report <- function(input, output_dir, output_file, ...) {
  rmarkdown::render(
    input,
    output_dir = output_dir,
    output_file = output_file
  )
  fs::path(output_dir, output_file)
}
