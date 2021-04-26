#' Calculate reliability for each measure
#'
#' @title
#' @param indices
#' @param resp_check
#' @return
#' @author Liang Zhang
#' @export
calc_reliability <- function(indices, resp_check) {
  name_key <- attr(indices, "name_key")
  data_retested <- indices %>%
    left_join(attr(indices, "meta"), by = name_key) %>%
    group_by(user_id, game_id) %>%
    mutate(times = row_number(game_time)) %>%
    filter(dplyr::n() > 1L) %>%
    ungroup() %>%
    pivot_longer(
      all_of(setdiff(names(indices), name_key)),
      names_to = "index",
      values_to = "score"
    ) %>%
    left_join(resp_check, by = name_key)
  data_retested %>%
    group_nest(game_id, index) %>%
    mutate(
      map_df(data, calc_icc3k, name_suffix = "_with_invalid"),
      map_df(
        data,
        ~ .x %>%
          filter(nc_okay, rr_okay) %>%
          calc_icc3k(name_suffix = "_no_invalid")
      ),
      map_df(
        data,
        ~ .x %>%
          filter(nc_okay, rr_okay) %>%
          mutate(
            score = ifelse(
              score %in% boxplot.stats(score)$out,
              NA, score
            )
          ) %>%
          calc_icc3k(name_suffix = "_no_outlier")
      ),
      .keep = "unused"
    )
}

calc_icc3k <- function(data, name_suffix = "") {
  if (nrow(data) == 0) {
    return(
      tibble(
        "n{name_suffix}" := 0,
        "icc{name_suffix}" := NA
      )
    )
  }
  data <- data %>%
    pivot_wider(
      user_id,
      names_from = "times",
      values_from = "score",
      names_prefix = "time_"
    ) %>%
    select(time_1, time_2)
  if (nrow(data) <= 1 ||
      # this checks if data from all times are actually the same or not
      length(unique.default(data)) == 1) {
    return(
      tibble(
        "n{name_suffix}" := nrow(data),
        "icc{name_suffix}" := NA
      )
    )
  }
  if (nrow(data) <= 1 ||
      # this checks if data from all times are actually the same or not
      length(unique.default(data)) == 1) {
    return(
      tibble(
        "n{name_suffix}" := nrow(data),
        "icc{name_suffix}" := NA
      )
    )
  }
  icc <- data %>%
    drop_na() %>%
    filter(is.finite(time_1), is.finite(time_2)) %>%
    psych::ICC()
  tibble(
    "n{name_suffix}" := pluck(icc, "n.obs"),
    "icc{name_suffix}" := pluck(icc, "results", "ICC", 6)
  )
}
