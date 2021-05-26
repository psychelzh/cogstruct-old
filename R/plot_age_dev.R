#' Plot score versus age scatter graphs
#'
#' @title
#' @param indices_clean
#' @param game_name_abbr
#' @param save_file
#' @return
#' @author Liang Zhang
#' @export
plot_age_dev <- function(indices_clean, game_name_abbr, save_file = TRUE) {
  filename <- fs::path("image", "age_dev", str_c(game_name_abbr, ".png"))
  data_valid <- indices_clean %>%
    filter(!is_outlier, !is.na(score), is.finite(score))
  if (nrow(data_valid) == 0) {
    p <- grid::grid.text(
      "No valid data samples.",
      gp = grid::gpar(fontsize = 20)
    )
    out_width <- 5
    out_height <- 2
  } else {
    p <- data_valid %>%
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
              color = "orange"
            ) +
            stat_cor(
              cor.coef.name = "r",
              r.accuracy = 0.001,
              p.accuracy = 0.001,
              show.legend = FALSE,
              color = "orange"
            ) +
            scale_x_continuous(breaks = 1:18) +
            labs(x = "Age", y = .y) +
            theme_pubclean()
        ),
        plot_distribution = map2(
          data, index,
          ~ .x %>%
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
    out_width <- 10
    out_height <- 3 * n_distinct(indices_clean$index) + 3
  }
  if (save_file) {
    ggsave(
      filename,
      plot = p,
      width = out_width,
      height = out_height,
      limitsize = FALSE,
      type = "cairo"
    )
    return(filename)
  } else {
    return(p)
  }
}

combine_plots <- function(plot_scatter, plot_distribution, plot_lines, ...) {
  plot_scatter + plot_distribution + plot_lines +
    plot_layout(widths = c(5, 1, 5))
}
