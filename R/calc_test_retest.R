#' Calculate reliability for each measure
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
calc_test_retest <- function(indices_clean) {
  indices_clean %>%
    group_by(user_id, game_id) %>%
    filter(max(occasion) > 1, occasion != 3) %>%
    ungroup() %>%
    group_nest(game_id, index) %>%
    mutate(
      map_df(data, calc_icc3k, name_suffix = "_with_invalid"),
      map_df(
        data,
        ~ .x %>%
          filter(is_valid) %>%
          calc_icc3k(name_suffix = "_no_invalid")
      ),
      map_df(
        data,
        ~ .x %>%
          filter(!is_outlier) %>%
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
        "icc{name_suffix}" := NA_real_
      )
    )
  }
  data <- data %>%
    pivot_wider(
      user_id,
      names_from = "occasion",
      values_from = "score",
      names_prefix = "occasion_"
    ) %>%
    select(starts_with("occasion"))
  if (nrow(data) <= 1) {
    return(
      tibble(
        "n{name_suffix}" := nrow(data),
        "icc{name_suffix}" := NA_real_
      )
    )
  }
  icc <- data %>%
    filter(
      if_all(
        starts_with("occasion"),
        ~ !is.na(.x) & is.finite(.x)
      )
    ) %>%
    psych::ICC()
  tibble(
    "n{name_suffix}" := pluck(icc, "n.obs"),
    "icc{name_suffix}" := pluck(icc, "results", "ICC", 2)
  )
}
