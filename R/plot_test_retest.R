#' Plot test-retest scatter plots
#'
#' @title
#' @param test_retest_data
#' @param game_name_abbr
#' @return
#' @author Liang Zhang
#' @export
plot_test_retest <- function(test_retest_data, game_name_abbr) {
  filename <- fs::path("image", "test_retest", str_c(game_name_abbr, ".png"))
  data <- filter(test_retest_data, !is_outlier)
  if (nrow(data) <= 1) {
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
  p <- data %>%
    group_nest(index) %>%
    mutate(
      plot_scatter = map2(
        data, index,
        ~ .x %>%
          ggplot(aes(test, retest)) +
          geom_point() +
          stat_cor(
            cor.coef.name = "r",
            r.accuracy = 0.001,
            p.accuracy = 0.001,
            show.legend = FALSE,
            color = "orange"
          ) +
          labs(x = "Test", y = "Re-Test", title = .y) +
          theme_bw() +
          theme(aspect.ratio = 1)
      ),
      plot_comparison = map2(
        data, index,
        ~ .x %>%
          pivot_longer(
            c(test, retest),
            names_to = "occasion",
            values_to = "score"
          ) %>%
          mutate(
            occasion = factor(
              occasion, c("test", "retest"), c("Test", "Retest")
            )
          ) %>%
          group_by(occasion) %>%
          summarise(mean_se(score)) %>%
          ggplot(aes(occasion, y, ymax = ymax, ymin = ymin)) +
          geom_point() +
          geom_errorbar(width = 0) +
          geom_line(group = 1) +
          labs(x = "", y = .y) +
          theme_pubclean()
      )
    ) %>%
    mutate(
      plots = map2(
        plot_scatter, plot_comparison,
        ~ .x + .y + plot_layout(widths = c(3, 5))
      )
    ) %>%
    pull(plots) %>%
    wrap_plots(ncol = 1L)
  ggsave(
    filename,
    plot = p,
    width = 10,
    height = 3 * n_distinct(test_retest_data$index) + 3,
    limitsize = FALSE,
    type = "cairo"
  )
  filename
}
