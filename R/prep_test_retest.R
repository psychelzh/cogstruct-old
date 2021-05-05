#' Prepare dataset for reliability analysis
#'
#' Some tests have A-B versions and should be treated specially.
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
prep_test_retest <- function(indices_clean) {
  indices_clean %>%
    group_by(user_id, game_id) %>%
    filter(max(occasion) > 1, occasion != 3) %>%
    ungroup() %>%
    mutate(occasion = factor(occasion, 1:2, c("test", "retest"))) %>%
    group_by(user_id, index) %>%
    mutate(
      is_valid = all(is_valid),
      is_outlier = any(is_outlier)
    ) %>%
    ungroup() %>%
    pivot_wider(
      c(user_id, game_id, index, is_valid, is_outlier),
      names_from = occasion,
      values_from = score
    )
}
