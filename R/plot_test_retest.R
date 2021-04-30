#' Plot test-retest scatter plots
#'
#' @title
#' @param indices_clean
#' @param game_name_abbr
#' @return
#' @author Liang Zhang
#' @export
plot_test_retest <- function(indices_clean, game_name_abbr) {
  filename <- fs::path("image", "test_retest", str_c(game_name_abbr, ".png"))
  data_with_retest <- indices_clean %>%
    group_by(user_id, game_id) %>%
    filter(!is_outlier) %>%
    filter(max(occasion) > 1, occasion != 3) %>%
    ungroup() %>%
    mutate(occasion = factor(occasion, 1:2, c("test", "retest"))) %>%
    pivot_wider(
      c(user_id, index),
      names_from = occasion,
      values_from = score
    )
  if (nrow(data_with_retest) <= 1) {
    ggsave(
      filename,
      grid::grid.text(
        "Not enough retest samples.",
        gp = grid::gpar(fontsize = 20)
      ),
      width = 5,
      height = 2,
      type = "cairo"
    )
    return(filename)
  }
  p <- ggplot(data_with_retest, aes(test, retest)) +
    geom_point() +
    stat_cor(cor.coef.name = "r", p.accuracy = 0.001, color = "darkblue") +
    facet_wrap(~ index, scales = "free", ncol = 1L) +
    labs(x = "Test", y = "Re-Test", color = "") +
    theme_bw() +
    theme(aspect.ratio = 1)
  ggsave(
    filename,
    plot = p,
    width = 10,
    height = 3 * n_distinct(indices_clean$index) + 3,
    limitsize = FALSE,
    type = "cairo"
  )
  filename
}
