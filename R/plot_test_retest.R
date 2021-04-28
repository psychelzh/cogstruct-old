#' Plot test-retest scatter plots
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
plot_test_retest <- function(indices_clean) {
  data_with_retest <- indices_clean %>%
    group_by(user_id, game_id) %>%
    filter(max(occasion) > 1, occasion != 3) %>%
    ungroup() %>%
    mutate(occasion = factor(occasion, 1:2, c("test", "retest"))) %>%
    group_by(user_id) %>%
    mutate(
      type = case_when(
        any(!is_valid) ~ "Invalid",
        all(is_valid) & any(is_outlier) ~ "Outlier",
        TRUE ~ "Normal"
      ) %>%
        factor(c("Normal", "Outlier", "Invalid"))
    ) %>%
    ungroup() %>%
    pivot_wider(
      c(user_id, index, type),
      names_from = occasion,
      values_from = score
    )
  if (nrow(data_with_retest) <= 1) {
    return()
  }
  ggplot(data_with_retest, aes(test, retest, color = type)) +
    geom_point(alpha = 0.5) +
    scale_color_viridis_d() +
    facet_wrap(~ index, scales = "free", ncol = 1L) +
    labs(x = "Test", y = "Re-Test", color = "") +
    theme_minimal() +
    theme(aspect.ratio = 1)
}
