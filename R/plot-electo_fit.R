#' Generate plots from electo_fit objects
#'
#' @param x Objeto electo_fit
#' @param kind "nacional", "seats_dist", "provincia", "dhondt_margin"
#' @param partido Party to highlight (used when kind="provincia")
#' @param ... Additional arguments (not used)
#'
#' @family visualization-functions
#' @family electo-fit-methods
#' @export
plot.electo_fit <- function(x, kind = c("nacional", "seats_dist", "provincia", "dhondt_margin"),
                            partido = NULL, ...) {
  kind <- match.arg(kind)

  if (kind == "nacional") {
    cols_seleccionadas <- c("partido", "pct_m", "pct_lwr", "pct_upr", "seats_m", "seats_lwr", "seats_upr")
    keep <- intersect(cols_seleccionadas, names(x$estimacion))
    if (length(keep) == 0) {
      stop(
        "`estimacion` does not contain any of the expectet columns: ",
        paste(cols_seleccionadas, collapse = ", ")
      )
    }
    df <- x$estimacion[, keep, drop = FALSE]
    df <- df[!df$partido %in% c("ABNL", "OTBL"), ] # excluir partidos no relevantes


    p <- ggplot(df, aes(reorder(partido, pct_m), pct_m)) +
      geom_col() +
      coord_flip() +
      labs(x = NULL, y = "Vote (%)", title = "National estimates") +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank()
      )
    if (all(c("pct_lwr", "pct_upr") %in% names(df))) {
      p <- p + geom_errorbar(aes(ymin = pct_lwr, ymax = pct_upr), width = .2)
    }
    if ("pct_m" %in% names(df)) {
      p <- p + expand_limits(y = max(df$pct_m, na.rm = TRUE) * 1.1)
    }
    print(p)
    return(invisible(p))
  }

  if (kind == "seats_dist") {
    es <- x$estimacion_sims
    es <- es[!es$partido %in% c("ABNL", "OTBL"), ]
    need <- c("partido", "seats")
    if (!all(need %in% names(es))) stop("Missing `estimacion_sims` with columns: partido, seats")
    p <- ggplot(es, aes(seats)) +
      geom_histogram(binwidth = 1) +
      facet_wrap(~partido) +
      labs(x = "Seats", y = "Freq", title = "Seat distribution") +
      theme_minimal(base_size = 12) +
      theme(
        panel.spacing = unit(1, "lines"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank()
      )
    print(p)
    return(invisible(p))
  }

  if (kind == "provincia") {
    ep <- x$estimacion_provincias_sims
    need <- c("sim", "codigo_provincia", "partido", "seats")
    if (!all(need %in% names(ep))) {
      stop("Missing `estimacion_provincias_sims` with columns: sim, codigo_provincia, partido, seats")
    }
    # resumen por provincia y partido: media e IC 5-95
    agg <- ep |>
      dplyr::group_by(codigo_provincia, partido) |>
      dplyr::summarise(
        mean = mean(seats, na.rm = TRUE),
        lwr = stats::quantile(seats, 0.05, na.rm = TRUE),
        upr = stats::quantile(seats, 0.95, na.rm = TRUE),
        .groups = "drop"
      )

    if (is.null(partido)) {
      tot <- aggregate(mean ~ partido, data = agg, sum)
      partido <- tot$partido[which.max(tot$mean)]
    }
    df <- dplyr::filter(agg, partido == !!partido)
    p <- ggplot(df, aes(reorder(codigo_provincia, mean), mean)) +
      geom_col() +
      geom_errorbar(aes(ymin = lwr, ymax = upr), width = .2) +
      coord_flip() +
      labs(
        x = "District", y = "Expected seats",
        title = paste0("Seats per district - ", partido)
      ) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank()
      )
    print(p)
    return(invisible(p))
  }

  if (kind == "dhondt_margin") {
    dh <- x$dhondt_output
    need <- c("codigo_provincia", "partido", "tipo", "dif")
    if (!all(need %in% names(dh))) {
      stop("Missing `dhondt_output` with columns: codigo_provincia, partido, tipo, dif")
    }
    agg <-
      filter(dh, dif > 0) %>%
      group_by(sim, codigo_provincia) %>%
      slice_min(dif, n = 1) %>%
      arrange(codigo_provincia, partido) %>%
      group_by(codigo_provincia) %>%
      summarise(dif = mean(dif))

    p <- ggplot(agg, aes(reorder(codigo_provincia, dif), dif)) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Provincia", y = "Mean margin of last quotient (D'Hondt)",
        title = "Seat fragility"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank()
      )
    print(p)
    return(invisible(p))
  }
}
