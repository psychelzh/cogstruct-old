#' Simplify Response Checking Results
#'
#' @title
#' @param resp_check
#' @return
#' @author Liang Zhang
#' @export
simplify_resp_check <- function(resp_check) {
  name_key <- attr(resp_check, "name_key")
  meta <- attr(resp_check, "meta")
  meta |>
    inner_join(resp_check, by = name_key) |>
    mutate(is_valid = nc_okay & rr_okay) |>
    select(user_id, game_id, game_time, is_valid)
}
