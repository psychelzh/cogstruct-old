#' Plot score versus age scatter graphs
#'
#' @title
#' @param indices_clean
#' @param game_name_abbr
#' @return
#' @author Liang Zhang
#' @export
plot_age_dev <- function(indices_clean, game_name_abbr) {
  file_name <- fs::path("image", "age_dev", str_c(game_name_abbr, ".png"))
  p <- indices_clean %>%
    group_nest(index) %>%
    mutate(
      plot_scatter = map2(
        data, index,
        ~ .x %>%
          ggplot(aes(user_age, score)) +
          geom_point() +
          geom_smooth(
            method = "lm",
            formula = y ~ x,
            color = "darkblue"
          ) +
          stat_cor(
            cor.coef.name = "r",
            p.accuracy = 0.001,
            show.legend = FALSE,
            color = "darkblue"
          ) +
          scale_x_continuous(breaks = 1:18) +
          scale_color_grey(guide = FALSE) +
          labs(x = "Age", y = .y) +
          theme_pubclean()
      ),
      plot_distribution = map2(
        data, index,
        ~ .x %>%
          filter(!is_outlier, !is.na(score), is.finite(score)) %>%
          ggplot(aes(score)) +
          geom_histogram(
            aes(y = after_stat(density)), bins = 30,
            fill = "white", color = "black"
          ) +
          geom_density(color = "lightblue") +
          coord_flip() +
          theme_void()
      ),
      plot_lines = map(
        data,
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
          scale_x_continuous(breaks = 1:18) +
          scale_color_viridis_d(labels = c(男 = "Male", 女 = "Female")) +
          labs(x = "Age", y = "", color = "Sex") +
          theme_pubclean()
      )
    ) %>%
    pmap(combine_plots) %>%
    wrap_plots(ncol = 1L) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
  ggsave(
    file_name,
    p,
    width = 10,
    height = 3 * n_distinct(indices_clean$index) + 3,
    limitsize = FALSE,
    type = "cairo"
  )
  file_name
}

combine_plots <- function(plot_scatter, plot_distribution, plot_lines, ...) {
  plot_scatter + plot_distribution + plot_lines +
    plot_layout(widths = c(5, 1, 5))
}
