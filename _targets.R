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
    tarflow.iquizoo::fetch(
      query_tmpl_data,
      tarflow.iquizoo::insert_where(
        config_where,
        list(table = "content", field = "Id", values = game_id)
      )
    )
  ),
  tar_target(
    indices,
    tarflow.iquizoo::calc_indices(data, prep_fun)
  ),
  tar_target(
    indices_smpl,
    simplify_indices(indices, game_name_abbr)
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
  tar_combine(indices, targets_data[[2]]),
  tar_combine(
    indices_smpl, targets_data[[3]],
    command = reduce(
      list(!!!.x),
      ~ full_join(.x, .y, by = c("user_id", "times"))
    )
  )
)
