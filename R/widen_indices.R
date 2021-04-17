#' Simplify indices object
#'
#' This will transform long formatted of indices object into a simplified widen
#' version.
#'
#' @title
#' @param indices
#' @param game_name_abbr
#' @return
#' @author Liang Zhang
#' @export
widen_indices <- function(indices, game_name_abbr) {
  indices %>%
    mutate(index = str_c(game_name_abbr, index, sep = "_")) %>%
    pivot_wider(names_from = index, values_from = score)
}
