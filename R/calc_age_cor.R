#' Calculate correlation between score and age
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
calc_age_cor <- function(indices_clean) {
  indices_clean %>%
    filter(!is_outlier, !is.na(score), is.finite(score)) %>%
    group_by(game_id, index) %>%
    summarise(
      cor_score_age = cor(user_age, score),
      .groups = "drop"
    )
}
