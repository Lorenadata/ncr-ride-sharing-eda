source(file.path("..", "..", "R", "features.R"), chdir = TRUE)

ejemplo <- function() {
  data.frame(
    date = as.Date(c("2024-01-05", "2024-03-10", "2024-09-30", "2024-10-01", "2024-12-24", "2024-06-15")),
    time = c("23:30:00", "08:15:00", "14:00:00", "03:45:00", "18:00:00", "12:00:00"),
    booking_status = c("Cancelled by Customer", "Completed", "Cancelled by Driver", "No Driver Found", "Incomplete", "Completed"),
    vehicle_type = c("Auto", "Go Sedan", "Auto", "eBike", "Uber XL", "Auto"),
    pickup_location = c("Palam Vihar", "Jhilmil", "Palam Vihar", "Saket", "Jhilmil", "Saket"),
    drop_location = c("Jhilmil", "Saket", "Saket", "Palam Vihar", "Saket", "Jhilmil"),
    avg_vtat = c(5.1, 8.2, NA, NA, 4.0, 7.7),
    booking_value = c(NA, 300, NA, NA, 250, 410),
    payment_method = c(NA, "UPI", NA, NA, "Cash", "UPI"),
    stringsAsFactors = FALSE
  )
}

test_that("el target vale 1 solo en las cancelaciones del cliente", {
  expect_equal(crear_target(ejemplo())$cancela_cliente, c(1L, 0L, 0L, 0L, 0L, 0L))
})

test_that("las variables del momento de reserva no incluyen nada posterior (sin fuga)", {
  v <- crear_variables(ejemplo(), "reserva")
  expect_length(setdiff(names(v), PERMITIDAS$reserva), 0)
  expect_false("avg_vtat" %in% names(v))
  expect_false(any(c("booking_value", "payment_method", "booking_status") %in% names(v)))
})

test_that("el escenario de asignación añade solo avg_vtat", {
  v <- crear_variables(ejemplo(), "asignacion")
  expect_setequal(setdiff(names(v), PERMITIDAS$reserva), "avg_vtat")
})

test_that("las 23:30 caen en la franja noche y las 03:45 en madrugada", {
  v <- crear_variables(ejemplo(), "reserva")
  expect_equal(as.character(v$franja[c(1, 4)]), c("noche", "madrugada"))
  expect_equal(v$hora[1], 23L)
})

test_that("una hora imposible da un error claro", {
  x <- ejemplo()
  x$time[2] <- "25:00:00"
  expect_error(crear_variables(x, "reserva"), "hora")
})

test_that("las categorías raras o nuevas en test pasan a 'otra'", {
  train <- data.frame(pickup_location = c(rep("A", 300), rep("B", 5)))
  test <- data.frame(pickup_location = c("A", "B", "C"))
  r <- colapsar_niveles(train, test, "pickup_location", min_n = 200)
  expect_equal(r$test$pickup_location, c("A", "otra", "otra"))
  expect_true(all(r$train$pickup_location %in% c("A", "otra")))
})

test_that("la partición temporal no deja fechas de octubre en train", {
  p <- particion_temporal(ejemplo(), corte = as.Date("2024-10-01"))
  expect_true(all(p$train$date < as.Date("2024-10-01")))
  expect_true(all(p$test$date >= as.Date("2024-10-01")))
  expect_equal(nrow(p$train) + nrow(p$test), 6)
})
