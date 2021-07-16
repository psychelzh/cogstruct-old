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

#' Prepare test-retest dataset for some special tests
#'
#' These tests have A-B versions.
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
prep_test_retest_sp <- function(indices_clean) {
  recode_ids <- tibble(
    name_from = c("BPSB", "DRIB", "NVRIB", "NVRDB", "FOLDB", "DRMB", "MRD", "MR3DB", "RavenSO"),
    name_to = c("BPSA", "DRIA", "NVRIA", "NVRDA", "FOLDA", "DRM", "MRC", "MR3DA", "RavenSE")
  ) %>%
    rowwise() %>%
    mutate(across(
      .fns = ~ with(game_info, game_id[game_name_abbr == .x])
    )) %>%
    deframe()
  indices_clean %>%
    filter(game_id %in% c(recode_ids, names(recode_ids))) %>%
    mutate(
      occasion = ifelse(game_id %in% names(recode_ids), 2, occasion),
      game_id = recode(game_id, !!!recode_ids)
    ) %>%
    prep_test_retest()
}

#' Calculate reliability for each measure
#'
#' @title
#' @param test_retest_data
#' @return
#' @author Liang Zhang
#' @export
calc_test_retest <- function(test_retest_data) {
  test_retest_data %>%
    group_nest(game_id, index) %>%
    mutate(
      map_df(
        data,
        ~ .x %>%
          select(test, retest) %>%
          calc_icc(name_suffix = "_with_invalid")
      ),
      map_df(
        data,
        ~ .x %>%
          filter(is_valid) %>%
          select(test, retest) %>%
          calc_icc(name_suffix = "_no_invalid")
      ),
      map_df(
        data,
        ~ .x %>%
          filter(!is_outlier) %>%
          select(test, retest) %>%
          calc_icc(name_suffix = "_no_outlier")
      ),
      .keep = "unused"
    )
}

calc_icc <- function(data, name_suffix = "") {
  if (nrow(data) <= 1) {
    return(
      tibble(
        "n{name_suffix}" := nrow(data),
        "icc{name_suffix}" := NA_real_
      )
    )
  }
  icc <- data %>%
    filter(if_all(.fns = ~ !is.na(.x) & is.finite(.x))) %>%
    psych::ICC()
  tibble(
    "n{name_suffix}" := pluck(icc, "n.obs"),
    "icc{name_suffix}" := pluck(icc, "results", "ICC", 3)
  )
}

#' Plot test-retest scatter plots
#'
#' @title
#' @param test_retest_data
#' @param game_name_abbr
#' @param suffix The suffix for the output file name.
#' @return
#' @author Liang Zhang
#' @export
plot_test_retest <- function(test_retest_data, game_name_abbr, suffix = "") {
  filename <- fs::path("image", "test_retest", str_c(game_name_abbr, suffix, ".png"))
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

#' Prapare test-retest data with stricter rules
#'
#' @title
#' @param indices_clean
#' @param count_invalid_resp
#' @param max_invalid
#' @return
#' @author Liang Zhang
#' @export
prep_test_retest_strict <- function(indices_clean, count_invalid_resp,
                                    max_invalid) {
  count_invalid_resp |>
    filter(n_invalid <= max_invalid) |>
    inner_join(indices_clean, by = c("user_id", "occasion")) |>
    prep_test_retest()
}

