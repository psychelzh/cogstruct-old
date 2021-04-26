library(targets)
library(tarchetypes)
purrr::walk(fs::dir_ls("R"), source)
future::plan(future::multisession)
search_games_mem <- memoise::memoise(
  tarflow.iquizoo::search_games,
  cache = cachem::cache_disk("~/.cache.tarflow.iquizoo")
)
games <- search_games_mem(config::get("where"))
tar_option_set(package = c("tidyverse", "dataproc.iquizoo"), imports = "dataproc.iquizoo")
targets_data <- tar_map(
  values = games,
  names = game_name_abbr,
  tar_target(
    data,
    tarflow.iquizoo::fetch_single_game(
      query_tmpl_data, config_where, game_id
    )
  ),
  tar_target(
    data_parsed,
    tarflow.iquizoo::wrangle_data(data)
  ),
  tar_target(
    indices,
    dataproc.iquizoo::preproc_data(
      data_parsed, prep_fun,
      by = attr(data_parsed, "name_key")
    )
  ),
  tar_target(
    config,
    dplyr::filter(
      config_resp,
      .data[["game_name_abbr"]] == game_name_abbr
    )
  ),
  tar_target(
    resp_check,
    check_resp_metric(data_parsed, config)
  ),
  tar_target(
    reliabilities,
    calc_reliability(indices, resp_check)
  )
)
list(
  tar_file(file_config, "config.yml"),
  tar_target(config_where, config::get("where", file = file_config)),
  tar_file(query_tmpl_users, fs::path("sql", "users.tmpl.sql")),
  tar_fst_tbl(users, tarflow.iquizoo::fetch(query_tmpl_users, config_where)),
  tar_file(query_tmpl_data, fs::path("sql", "data.tmpl.sql")),
  tar_file(query_tmpl_games, fs::path("sql", "games.tmpl.sql")),
  targets_data,
  tar_file(file_config_resp, "config/config_resp_metric.csv"),
  tar_target(config_resp, read_csv(file_config_resp, col_types = cols())),
  tar_combine(
    indices,
    targets_data[[3]],
    command = combine_branches(
      list(!!!.x),
      names_to = "index",
      values_to = "score"
    )
  ),
  tar_combine(
    resp_check,
    targets_data[[5]],
    command = combine_branches(list(!!!.x), stack = FALSE)
  ),
  tar_combine(reliabilities, targets_data[[6]])
)
