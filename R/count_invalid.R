#' Cleanse users according to responses
#'
#' @title
#' @param resp_check
#' @return
#' @author Liang Zhang
#' @export
count_invalid <- function(resp_check) {
  resp_check |>
    group_by(user_id, game_id) |>
    mutate(occasion = row_number(game_time)) |>
    group_by(user_id, occasion) |>
    summarise(n_invalid = sum(!is_valid), .groups = "drop")
}
