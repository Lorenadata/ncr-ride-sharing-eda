# Construye el JSON que usa la web a partir de los resultados que guarda el informe (modelo/resultados.rds).
# No reentrena nada: las cifras son exactamente las del informe.
MIN_RESERVAS <- 100

construir_json <- function(r) {
  t <- r$test_A
  grupos <- split(t, list(t$vehicle_type, t$franja, t$finde), drop = TRUE)
  celdas <- lapply(grupos, function(g) list(
    vehicle_type = as.character(g$vehicle_type[1]), franja = as.character(g$franja[1]),
    finde = as.integer(g$finde[1]), prob_media = round(mean(g$p), 4), n = nrow(g)))
  celdas <- Filter(function(c) c$n >= MIN_RESERVAS, unname(celdas))
  metr <- function(x) list(base = list(pr_auc = x$base$pr_auc), logistica = x$logistica, xgboost = x$xgboost)
  list(
    prevalencia = r$A$prevalencia,
    metricas = metr(r$A),
    asignacion = c(metr(r$B), list(prevalencia = r$B$prevalencia)),
    celdas = celdas,
    importancia = lapply(seq_len(min(5, nrow(r$A$importancia))), function(i) list(variable = r$A$importancia$variable[i], gain = round(r$A$importancia$Gain[i], 4))),
    importancia_asignacion = lapply(seq_len(min(5, nrow(r$B$importancia))), function(i) list(variable = r$B$importancia$variable[i], gain = round(r$B$importancia$Gain[i], 4)))
  )
}
