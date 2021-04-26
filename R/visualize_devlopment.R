#' Plot score versus age scatter graphs
#'
#' @title
#' @param indices
#' @param resp_check
#' @param users
#' @return
#' @author Liang Zhang
#' @export
visualize_devlopment <- function(indices, resp_check, users) {
  name_key <- attr(indices, "name_key")
  data <- attr(indices, "meta") %>%
    left_join(users, by = "user_id") %>%
    mutate(
      age = (user_dob %--% game_time) / dyears(),
      age_int = round(age)
    ) %>%
    left_join(indices, by = name_key) %>%
    pivot_longer(
      all_of(setdiff(names(indices), name_key)),
      names_to = "index",
      values_to = "score"
    ) %>%
    left_join(resp_check, by = name_key) %>%
    mutate(
      is_normal = ifelse(nc_okay & rr_okay, "Valid", "Invalid") %>%
        factor(c("Valid", "Invalid"))
    ) %>%
    group_by(age_int) %>%
    filter(n() > 100) %>%
    ungroup()
  ggplot(data, aes(age, score, color = is_normal)) +
    geom_point() +
    geom_smooth(
      data = filter(data, is_normal == "Valid"),
      method = "lm",
      formula = y ~ x
    ) +
    stat_cor(
      data = filter(data, is_normal == "Valid"),
      cor.coef.name = "r",
      p.accuracy = 0.001,
      show.legend = FALSE
    ) +
    facet_wrap(~ index, ncol = 1L, scales = "free_y") +
    scale_color_grey() +
    theme_pubclean() +
    labs(x = "Age", y = "Score", color = "")
}
