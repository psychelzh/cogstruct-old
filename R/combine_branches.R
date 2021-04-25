#' Combine results from branches
#'
#' This function will use metadata combine results from all branches.
#'
#' @param targets A `list` with names. The targets data from branches.
#' @param stack A `logical` value indicating if stack is required.
#' @param ... Additional arguments passed on to [tidyr::pivot_longer()].
#'
#' @export
combine_branches <- function(targets, stack = TRUE, ...) {
  # merge meta and data then join branches
  targets %>%
    imap(wrangle_meta, stack = stack, ...) %>%
    bind_rows()
}

wrangle_meta <- function(data, name, stack, ...) {
  if (is.null(data)) {
    return(NULL)
  }
  meta <- attr(data, "meta")
  name_key <- attr(data, "name_key")
  data_cols <- setdiff(names(data), name_key)
  data_and_meta <- data %>%
    add_column(game_name_abbr = str_extract(name, "(?<=_)[^_]+$")) %>%
    left_join(meta, by = name_key) %>%
    group_by(user_id, game_id, ) %>%
    mutate(times = row_number(game_time)) %>%
    ungroup() %>%
    select(user_id, game_id, game_name_abbr, times, all_of(data_cols))
  if (stack) {
    data_and_meta <- data_and_meta %>%
      pivot_longer(all_of(data_cols), ...)
  }
  data_and_meta
}
