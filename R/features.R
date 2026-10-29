# Preparación de datos para el modelo de cancelaciones por parte del cliente.
# Regla de oro: solo se usan variables que existen en el momento de la predicción (sin fuga de información).

# Variables permitidas en cada escenario.
#   reserva:    lo que se sabe cuando el cliente pide el viaje.
#   asignacion: además, el tiempo estimado de llegada del vehículo (avg_vtat), que solo existe con conductor asignado.
# El mes no se usa: con un solo año de datos y partición temporal, los meses de test nunca aparecen al entrenar.
PERMITIDAS <- list(
  reserva = c("dia_semana", "finde", "hora", "franja", "vehicle_type", "pickup_location", "drop_location"),
  asignacion = c("dia_semana", "finde", "hora", "franja", "vehicle_type", "pickup_location", "drop_location", "avg_vtat")
)

# Lee el CSV de Kaggle con los nombres en snake_case, sin comillas sobrantes en los IDs y con "null" como NA.
leer_reservas <- function(path) {
  d <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("null", ""))
  names(d) <- gsub("[^a-z0-9]+", "_", tolower(names(d)))
  for (v in c("booking_id", "customer_id")) d[[v]] <- gsub('"', "", d[[v]], fixed = TRUE)
  d$date <- as.Date(d$date)
  d$avg_vtat <- as.numeric(d$avg_vtat)
  d
}

crear_target <- function(df) {
  df$cancela_cliente <- as.integer(df$booking_status == "Cancelled by Customer")
  df
}

franja_horaria <- function(hora) {
  cut(hora, breaks = c(-1, 5, 11, 17, 23), labels = c("madrugada", "manana", "tarde", "noche"))
}

crear_variables <- function(df, escenario = c("reserva", "asignacion")) {
  escenario <- match.arg(escenario)
  h <- suppressWarnings(as.integer(substr(df$time, 1, 2)))
  if (anyNA(h) || any(h < 0 | h > 23)) stop("Hay valores de hora imposibles en 'time' (se esperaba HH:MM:SS entre 00 y 23)")
  if (anyNA(df$date)) stop("Hay fechas vacías o inválidas en 'date'")
  out <- data.frame(
    dia_semana = factor(as.POSIXlt(df$date)$wday, levels = 0:6),
    finde = as.integer(as.POSIXlt(df$date)$wday %in% c(0, 6)),
    hora = h,
    franja = franja_horaria(h),
    vehicle_type = df$vehicle_type,
    pickup_location = df$pickup_location,
    drop_location = df$drop_location,
    stringsAsFactors = FALSE
  )
  if (escenario == "asignacion") out$avg_vtat <- df$avg_vtat
  out[PERMITIDAS[[escenario]]]
}

# Agrupa en "otra" las categorías con menos de min_n casos en train y las que solo aparecen en test.
colapsar_niveles <- function(train, test, col, min_n = 200) {
  cuenta <- table(train[[col]])
  frecuentes <- names(cuenta)[cuenta >= min_n]
  train[[col]] <- ifelse(train[[col]] %in% frecuentes, train[[col]], "otra")
  test[[col]] <- ifelse(test[[col]] %in% frecuentes, test[[col]], "otra")
  list(train = train, test = test)
}

particion_temporal <- function(df, corte = as.Date("2024-10-01")) {
  list(train = df[df$date < corte, , drop = FALSE], test = df[df$date >= corte, , drop = FALSE])
}
