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
