#' Prepare dataset of exploratory factor analysis
#'
#' @title
#' @param indices_clean
#' @param config_selection
#' @param rm
#' @return
#' @author Liang Zhang
#' @export
prep_efa_dataset <- function(indices_clean, config_selection, rm = NULL) {
  if (is.null(rm)) {
    rm <- "outlier"
  }
  indices_used <- switch(
    rm,
    none = indices_clean,
    invalid = indices_clean %>%
      filter(is_valid),
    outlier = indices_clean %>%
      filter(!is_outlier)
  )
  config_selection %>%
    filter(!type %in% c("exclude", "outcome")) %>%
    left_join(indices_used, by = c("game_id", "index")) %>%
    filter(occasion == 1) %>%
    mutate(score = score * (-1) ^ inversed) %>%
    unite(game_index, game_name_abbr, index) %>%
    pivot_wider(user_id, names_from = game_index, values_from = score)
}
