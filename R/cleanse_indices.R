#' Add age to indices
#'
#' @title
#' @param indices
#' @param resp_check
#' @param users
#' @return
#' @author Liang Zhang
#' @export
cleanse_indices <- function(indices, resp_check, users) {
  name_key <- attr(indices, "name_key")
  attr(indices, "meta") %>%
    left_join(users, by = "user_id") %>%
    group_by(user_id) %>%
    mutate(occasion = row_number(game_time)) %>%
    ungroup() %>%
    mutate(
      user_age = (user_dob %--% game_time) / dyears(),
      user_age_int = round(user_age)
    ) %>%
    left_join(indices, by = name_key) %>%
    pivot_longer(
      all_of(setdiff(names(indices), name_key)),
      names_to = "index",
      values_to = "score"
    ) %>%
    left_join(resp_check, by = name_key) %>%
    mutate(is_valid = nc_okay & rr_okay) %>%
    group_by(user_age_int) %>%
    # remove ages with too few samples
    filter(n() >= 100) %>%
    # check outliers
    group_by(index, is_valid) %>%
    mutate(
      is_outlier = ifelse(
        !is_valid | (is_valid & score %in% boxplot.stats(score)$out),
        TRUE, FALSE
      )
    ) %>%
    ungroup() %>%
    select(
      user_id, user_sex, user_age, user_age_int,
      game_id, occasion, index, score,
      is_valid, is_outlier
    )
}
