source(file.path("..", "..", "R", "export.R"), chdir = TRUE)

resultados_ejemplo <- function() {
  set.seed(1)
  n <- 600
  list(
    A = list(prevalencia = 0.07, base = list(pr_auc = 0.07), logistica = list(pr_auc = 0.072, roc_auc = 0.508),
             xgboost = list(pr_auc = 0.071, roc_auc = 0.502, umbral = 0.06, precision = 0.07, recall = 0.99),
             importancia = data.frame(variable = c("hora", "drop_location"), Gain = c(0.6, 0.4))),
    B = list(prevalencia = 0.075, base = list(pr_auc = 0.075), logistica = list(pr_auc = 0.46, roc_auc = 0.77),
             xgboost = list(pr_auc = 0.484, roc_auc = 0.773, umbral = 0.63, precision = 0.997, recall = 0.349),
             importancia = data.frame(variable = "avg_vtat", Gain = 1)),
    test_A = data.frame(vehicle_type = rep(c("Auto", "eBike"), c(500, 100)), franja = "tarde", finde = rep(c(0L, 1L), 300), p = runif(n, 0, 0.2))
  )
}

test_that("ninguna celda publicada tiene menos de 100 reservas", {
  j <- construir_json(resultados_ejemplo())
  expect_true(all(sapply(j$celdas, `[[`, "n") >= 100))
  expect_false(any(sapply(j$celdas, `[[`, "vehicle_type") == "eBike" & sapply(j$celdas, `[[`, "finde") == 1L & sapply(j$celdas, `[[`, "n") < 100))
})

test_that("las probabilidades están entre 0 y 1", {
  j <- construir_json(resultados_ejemplo())
  p <- sapply(j$celdas, `[[`, "prob_media")
  expect_true(all(p >= 0 & p <= 1))
})

test_that("las métricas son exactamente las del informe", {
  r <- resultados_ejemplo()
  j <- construir_json(r)
  expect_equal(j$metricas$xgboost$pr_auc, r$A$xgboost$pr_auc)
  expect_equal(j$asignacion$xgboost$pr_auc, r$B$xgboost$pr_auc)
  expect_equal(j$prevalencia, r$A$prevalencia)
})
