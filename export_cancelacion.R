# Uso: Rscript export_cancelacion.R <modelo/resultados.rds> <salida.json>
# Antes hay que generar el informe (quarto render modelo_cancelaciones.qmd), que guarda modelo/resultados.rds.
source("R/export.R")
args <- commandArgs(TRUE)
stopifnot(length(args) == 2)
j <- construir_json(readRDS(args[1]))
jsonlite::write_json(j, args[2], auto_unbox = TRUE, digits = NA, pretty = TRUE)
cat("OK", args[2], ":", length(j$celdas), "celdas\n")
