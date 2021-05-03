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
  games_a <- c("BPSA", "DRIA", "NVRIA", "NVRDA", "FOLDA", "DRM", "MRC", "MR3DA", "RavenSE")
  games_b <- c("BPSB", "DRIB", "NVRIB", "NVRDB", "FOLDB", "DRMB", "MRD", "MR3DB", "RavenSO")
  games_id_a <- with(game_info, game_id[game_name_abbr %in% games_a])
  games_id_b <- with(game_info, game_id[game_name_abbr %in% games_b])
  recode_ids <- set_names(games_id_a, games_id_b)
  indices_clean %>%
    filter(game_id %in% c(games_id_a, games_id_b)) %>%
    mutate(
      occasion = ifelse(game_id %in% games_id_b, 2, occasion),
      game_id = recode(game_id, !!!recode_ids)
    )
}
