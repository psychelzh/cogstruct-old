library(targets)
library(tarchetypes)
purrr::walk(fs::dir_ls("R"), source)
future::plan(future::multisession)
search_games_mem <- memoise::memoise(
  tarflow.iquizoo::search_games,
  cache = cachem::cache_disk("~/.cache.tarflow.iquizoo")
)
games <- search_games_mem(config::get("where"))
tar_option_set(
  package = c("tidyverse", "dataproc.iquizoo", "lubridate", "ggpubr"),
  imports = "dataproc.iquizoo"
)
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
    preproc_data(
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
    indices_clean,
    cleanse_indices(indices, resp_check, users)
  ),
  tar_target(
    reliabilities,
    calc_reliability(indices_clean)
  ),
  tar_target(
    age_dev_plot,
    visualize_devlopment(indices_clean)
  ),
  tar_file(
    file_age_dev, {
      file_name <- fs::path("image", "age_dev", str_c(game_name_abbr, ".png"))
      ggsave(
        file_name,
        age_dev_plot +
          labs(title = game_name_en) +
          theme(plot.title = element_text(hjust = 0.5)),
        width = 6,
        height = 3 * ncol(indices),
        limitsize = FALSE,
        type = "cairo"
      )
      file_name
    }
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
  tar_combine(indices_clean, targets_data[[6]]),
  tar_combine(reliabilities, targets_data[[7]])
)
