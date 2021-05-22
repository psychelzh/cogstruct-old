#' Prepare test-retest dataset for some special tests
#'
#' These tests have A-B versions.
#'
#' @title
#' @param indices_clean
#' @return
#' @author Liang Zhang
#' @export
prep_test_retest_sp <- function(indices_clean) {
  recode_ids <- tibble(
    name_from = c("BPSB", "DRIB", "NVRIB", "NVRDB", "FOLDB", "DRMB", "MRD", "MR3DB", "RavenSO"),
    name_to = c("BPSA", "DRIA", "NVRIA", "NVRDA", "FOLDA", "DRM", "MRC", "MR3DA", "RavenSE")
  ) %>%
    rowwise() %>%
    mutate(across(
      .fns = ~ with(game_info, game_id[game_name_abbr == .x])
    )) %>%
    deframe()
  indices_clean %>%
    filter(game_id %in% c(recode_ids, names(recode_ids))) %>%
    mutate(
      occasion = ifelse(game_id %in% names(recode_ids), 2, occasion),
      game_id = recode(game_id, !!!recode_ids)
    ) %>%
    prep_test_retest()
}
