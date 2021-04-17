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
    indices_widen,
    widen_indices(indices, game_name_abbr)
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
  tar_combine(data, targets_data[[1]]),
  tar_combine(data_parsed, targets_data[[2]]),
  tar_combine(indices, targets_data[[3]]),
  tar_combine(indices_widen, targets_data[[4]])
)
