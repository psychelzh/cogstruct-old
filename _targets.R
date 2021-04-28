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
  package = c("tidyverse", "dataproc.iquizoo", "lubridate", "ggpubr", "patchwork"),
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
    test_retest_stats,
    calc_test_retest(indices_clean)
  ),
  tar_file(
    file_test_retest_plot,
    plot_test_retest(indices_clean, game_name_abbr)
  ),
  tar_target(
    age_dev_stats,
    calc_age_dev(indices_clean)
  ),
  tar_file(
    file_age_dev_plot,
    plot_age_dev(indices_clean, game_name_abbr)
  )
)
list(
  tar_target(games_included, games),
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
  tar_combine(test_retest_stats, targets_data[[7]]),
  tar_combine(age_dev_stats, targets_data[[9]]),
  tar_file(file_config_selection, "config/index_selection.csv"),
  tar_target(
    config_selection,
    read_csv(file_config_selection, col_types = cols())
  ),
  tar_target(
    indices_efa_full,
    prep_efa_dataset(indices_clean, config_selection)
  ),
  tar_target(
    indices_efa_valid,
    prep_efa_dataset(indices_clean, config_selection, rm = "invalid")
  ),
  tar_target(
    indices_efa_normal,
    prep_efa_dataset(indices_clean, config_selection, rm = "outlier")
  ),
  tar_file(
    rmd_child_check_index,
    "archetypes/child_check_index.Rmd"
  ),
  tar_file(
    rmd_report,
    "docs/explore_structure.Rmd"
  ),
  tar_render(
    report,
    "docs/explore_structure.Rmd",
    output_dir = "report"
  )
)
