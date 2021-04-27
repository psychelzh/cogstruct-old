#' Plot score versus age scatter graphs
#'
#' @title
#' @param indices
#' @param resp_check
#' @param users
#' @return
#' @author Liang Zhang
#' @export
visualize_devlopment <- function(indices_clean) {
  indices_clean %>%
    filter(!is_outlier) %>%
    ggplot(aes(user_age, score)) +
    geom_point() +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      color = "grey"
    ) +
    stat_cor(
      cor.coef.name = "r",
      p.accuracy = 0.001,
      show.legend = FALSE,
      color = "grey"
    ) +
    facet_wrap(~ index, ncol = 1L, scales = "free_y") +
    theme_pubclean() +
    labs(x = "Age", y = "Score")
}
