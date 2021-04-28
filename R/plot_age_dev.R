#' Plot score versus age scatter graphs
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
plot_age_dev <- function(indices_clean) {
  indices_clean %>%
    group_nest(index) %>%
    mutate(
      plot_scatter = map2(
        data, index,
        ~ .x %>%
          filter(!is_outlier) %>%
          ggplot(aes(user_age, score, color = is_outlier)) +
          geom_point(data = .x) +
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
          scale_color_grey(guide = FALSE) +
          labs(x = "Age", y = .y)
      ),
      plot_lines = map2(
        data, index,
        ~ .x %>%
          filter(!is_outlier, !is.na(score), is.finite(score)) %>%
          group_by(user_age_int, user_sex) %>%
          summarise(n = n(), mean_se(score), .groups = "drop") %>%
          ggplot(aes(
            user_age_int, y,
            ymin = ymin, ymax = ymax,
            color = user_sex
          )) +
          geom_point(position = position_dodge(width = 0.1)) +
          geom_line(position = position_dodge(width = 0.1)) +
          geom_errorbar(position = position_dodge(width = 0.1), width = 0) +
          ggrepel::geom_text_repel(aes(label = n), show.legend = FALSE) +
          scale_color_viridis_d(labels = c(男 = "Male", 女 = "Female")) +
          labs(x = "Age", y = .y, color = "Sex")
      ),
      plot_combined = map2(
        plot_scatter, plot_lines,
        ~ .x + .y &
          scale_x_continuous(breaks = 1:18) &
          theme_pubclean()
      )
    ) %>%
    pull(plot_combined) %>%
    wrap_plots(ncol = 1L) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
}
