#' Check reponse metric
#'
#' Here we implement the two basic metric checks of count of correct responses
#' and response rate. Details are currently in "config/README.md".
#'
#' @title
#' @param data
#' @param config
#' @return
#' @author Liang Zhang
#' @export
check_resp_metric <- function(data, config) {
  if (is.na(config$resp_type)) {
    return(NULL)
  }
  if (!is.na(config$filter)) {
    data <- filter(data, !!rlang::parse_expr(config$filter))
  }
  .prepare_resp_metric(data, config) %>%
    mutate(
      nc_min = coalesce(qbinom(0.95, nt, config$chance_acc), -Inf),
      nc_max = coalesce(qbinom(0.05, nt, config$cheat_acc), Inf),
      nt_min = if (config$resp_type == "required_easy") {
        config$duration * 60 / (config$iti + 3)
      } else {
        -Inf
      },
      nt_max = if (config$resp_type == "required_easy") {
        config$duration * 60 / (config$iti + 0.3)
      } else if (config$resp_type == "required_hard") {
        config$duration * 60 / (config$iti + 2)
      } else {
        Inf
      }
    ) %>%
    rowwise() %>%
    mutate(
      nc_okay = between(nc, nc_min, nc_max),
      rr_okay = pm <= 0.2 & between(nt, nt_min, nt_max)
    ) %>%
    ungroup() %>%
    vctrs::vec_restore(data)
}

.prepare_resp_metric <- function(data, config) {
  if (config$name_acc == "SEPARATED") {
    resp_metric <- data %>%
      group_by(.id) %>%
      summarise(
        nc = sum(ncorrect),
        nt = nc + sum(ncorrect),
        pm = 0,
        .groups = "drop"
      )
  } else {
    if (config$name_acc == "CALCULATED") {
      data <- switch(
        config$game_name_abbr,
        NLEJr = ,
        NLEMed = mutate(
          data,
          acc = as.integer(abs(resp - number) <= config$crit_acc)
        ),
        JLO = data %>%
          mutate(
            resp_angle = str_split(tolower(resp), "-") %>%
              map_dbl(~ sum((.x == "left") * 2 - 1) * 6),
            # line is undirected
            resp_err = 90 - abs((resp_angle - angle) %% 180 - 90),
            acc = as.integer(resp_err <= config$crit_acc)
          ),
        SRT = ,
        SRTS = ,
        MltSns = mutate(data, acc = 1L - 2L * (rt == 0)),
        SSTM = ,
        SSTMSpd = data %>%
          mutate(
            stim = dataproc.iquizoo:::parse_char_resp(stim),
            resp = dataproc.iquizoo:::parse_char_resp(resp),
            acc = map2(stim, resp, ~ as.integer(.x == .y))
          ) %>%
          unnest(acc)
      )
    } else {
      if (is.character(data[[config$name_acc]])) {
        data <- data %>%
          mutate(
            "{config$name_acc}" :=
              dataproc.iquizoo:::parse_char_resp(.data[[config$name_acc]])
          ) %>%
          unnest(.data[[config$name_acc]])
      }
      # TODO: use better structure of configuration
      if (config$crit_acc > 0) {
        data <- data %>%
          mutate(acc = as.integer(.data[[config$name_acc]] <= config$crit_acc))
      } else if (config$crit_acc == 0) {
        data <- data %>%
          mutate(
            acc = ifelse(
              .data[[config$name_acc]] %in% c(0, 1),
              .data[[config$name_acc]], -1L
            )
          )
      } else if (config$crit_acc == -1) {
        data <- data %>%
          mutate(acc = (.data[[config$name_acc]] == 1) * 2L  - 1L)
      }
    }
    resp_metric <- data %>%
      group_by(.id) %>%
      summarise(
        nc = sum(acc == 1),
        nt = n(),
        pm = mean(acc == -1),
        .groups = "drop"
      )
  }
  resp_metric
}
