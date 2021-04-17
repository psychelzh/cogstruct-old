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
simplify_indices <- function(indices, game_name_abbr) {
  indices %>%
    group_by(user_id, index) %>%
    mutate(
      times = row_number(game_time),
      index = str_c(game_name_abbr, index, sep = "_")
    ) %>%
    ungroup() %>%
    select(user_id, times, index, score) %>%
    pivot_wider(names_from = index, values_from = score)
}
