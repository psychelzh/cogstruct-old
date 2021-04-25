sim_hop <- function(radius = 200, crit = 100, nrep = 10000, digits = 0) {
  coord_x <- round(runif(2 * nrep, -radius, radius))
  max_coord_y <- sqrt(radius ^ 2 - coord_x ^ 2)
  coord_y <- round(map_dbl(max_coord_y, ~ runif(1, -.x, .x)))
  get_chance(coord_x, coord_y, crit, digits)
}

sim_locmemadv <- function(size = 17, crit = 5, nrep = 10000, digits = 2) {
  coord_x <- round(runif(2 * nrep, 1, size))
  coord_y <- round(runif(2 * nrep, 1, size))
  get_chance(coord_x, coord_y, crit, digits)
}

sim_nle <- function(size = 10, crit = 1, nrep = 10000, digits = 0) {
  coord_x <- round(runif(2 * nrep, 1, size))
  get_chance(coord_x, coord_y = NULL, crit, digits)
}

sim_locmem <- function(size_x = 6, size_y = 10, crit = 3,
                       nrep = 10000, digits = 2) {
  coord_x <- round(runif(2 * nrep, 1, size_x))
  coord_y <- round(runif(2 * nrep, 1, size_y))
  get_chance(coord_x, coord_y, crit, digits)
}

get_chance <- function(coord_x, coord_y, crit, digits) {
  bind_rows(
    compose_coord_tbl(coord_x, "x", c("start", "end")),
    if (!is.null(coord_y))
      compose_coord_tbl(coord_y, "y", c("start", "end"))
  ) %>%
    pivot_wider(names_from = "type", values_from = "coord") %>%
    group_by(id) %>%
    summarise(
      dist = round(sqrt(sum((start - end) ^ 2)), digits),
      .groups = "drop"
    ) %>%
    summarise(chance = mean(dist <= crit)) %>%
    pull(chance)
}

compose_coord_tbl <- function(coords, axis, types) {
  nrep <- length(coords) / length(types)
  tibble(
    id = rep(seq_len(nrep), times = length(types)),
    type = rep(types, each = nrep),
    axis = axis,
    coord = coords
  )
}
