library(ggplot2)
library(dplyr)
library(patchwork)  # Para mostrar gráficos juntos

# ================================================
# 1. OUTLIERS Y EXTREMOS
# ================================================ 

outliers_extreme <- function(data, variable) {
  var_name <- data[[variable]]  # Acceder a la variable por nombre
  
  tot <- sum(!is.na(var_name))  # Total de observaciones no NA
  na1 <- sum(is.na(var_name))   # NA iniciales
  
  # Identificar outliers usando la regla de Tukey (coef = 1.5)
  stats1 <- boxplot.stats(var_name, coef = 1.5)
  outlier_values <- stats1$out  
  prop_outliers <- round(length(outlier_values) / tot * 100, 2)  # Proporción de outliers
  
  # Identificar extremos usando la regla de Tukey (coef = 3)
  stats2 <- boxplot.stats(var_name, coef = 3)
  extreme_values <- stats2$out  
  prop_extreme <- round(length(extreme_values) / tot * 100, 2)  # Proporción de extremos
  
  # Preparar dataframe para los gráficos y clasificar los puntos
  df_plot <- data.frame(value = var_name)
  df_plot$tipo <- "Normal"
  
  # Usamos los bigotes de stats1 (1.5 IQR) y stats2 (3 IQR) para clasificar con precisión
  df_plot$tipo[df_plot$value < stats1$stats[1] | df_plot$value > stats1$stats[5]] <- "Atípico"
  df_plot$tipo[df_plot$value < stats2$stats[1] | df_plot$value > stats2$stats[5]] <- "Extremo"
  
  # Extraemos solo los puntos anómalos para pintarlos por encima en p2
  df_anomalos <- subset(df_plot, tipo != "Normal")
  
  # 1. Histograma con todos los datos
  p1 <- ggplot(df_plot, aes(x = value)) +
    geom_histogram(fill = "steelblue", color = "black", bins = 30, alpha = 0.7) +
    labs(title = paste("All Observations:", variable), x = variable, y = "Count") +
    theme_minimal()
  
  # 2. Boxplot con outliers y extremos resaltados
  p2 <- ggplot(df_plot, aes(x = value, y = factor(1))) +
    # Boxplot base 
    geom_boxplot(outlier.shape = NA, fill = "white", color = "black") +
    
    # Añadimos nuestros puntos con colores. 
    # show.legend = FALSE evita que se cree la leyenda en el gráfico
    geom_point(data = df_anomalos, aes(color = tipo), size = 3.5, shape = 16, show.legend = FALSE) +
    
    scale_color_manual(values = c("Atípico" = "orange", "Extremo" = "red")) +
    labs(title = "Boxplot with Outliers & Extremes", x = variable, y = "") +
    theme_minimal() +
    
    # Limpiamos el eje Y y nos aseguramos de que no haya ninguna leyenda
    theme(axis.text.y = element_blank(), 
          axis.ticks.y = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          legend.position = "none") #
  
  # Mostrar gráficos juntos con patchwork
  print(p1 / p2)
  
  # Mostrar información en la consola
  cat("\n🟠 Atípicos (Outliers) en", variable, ": ", length(outlier_values), "\n")
  cat("   🔸 Proporción (%):", prop_outliers, "%\n")
  
  cat("\n🔴 Extremos (Extreme values) en", variable, ": ", length(extreme_values), "\n")
  cat("   🔻 Proporción (%):", prop_extreme, "%\n")
  
  return(outlier_values)  # Devolver los valores outliers sin modificar los datos
}



# ================================================
# 2. BIVARIANTE: CUANTITATIVA VS CUALITATIVA
# ================================================
bivariante_box <- function(data, var_num, var_cat) {
  ggplot(data, aes(x = as.factor(.data[[var_cat]]), 
                   y = .data[[var_num]])) +
    geom_boxplot(fill = "lightblue", outlier.color = "red", 
                 outlier.shape = 16) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = paste(var_num, "por", var_cat),
         x = var_cat, y = var_num)
}

# ================================================
# 3. BIVARIANTE: CUANTITATIVA VS CUANTITATIVA
# ================================================
bivariante_scatter <- function(data, var_x, var_y) {
  ggplot(data, aes(x = .data[[var_x]], y = .data[[var_y]])) +
    geom_point(alpha = 0.3, color = "steelblue") +
    stat_smooth(method = "lm", formula = y ~ x, color = "red") +
    theme_minimal() +
    labs(title = paste(var_y, "vs", var_x),
         x = var_x, y = var_y)
}

# ================================================
# 4. LOF COMPLETO CON PCA
# ================================================
calcular_lof <- function(data, umbral = 1.5) {
  
  # Selección, limpieza y escalado
  datos <- data |> 
    select(where(is.numeric)) |> 
    na.omit() |> 
    select(where(~var(.) > 0))
  
  datos_scaled <- scale(datos)
  
  # Cálculo LOF
  k <- round(log(nrow(datos)))
  scores <- lof(datos_scaled, minPts = k)
  datos <- datos |> mutate(lof_score = scores)
  
  # Boxplot de scores
  p1 <- ggplot(datos, aes(x = lof_score)) +
    geom_boxplot(fill = "skyblue", outlier.color = "red", 
                 outlier.shape = 16) +
    theme_minimal() +
    labs(title = "Distribución de LOF Scores")
  
  # PCA
  pca_res <- prcomp(datos_scaled, center = TRUE)
  df_pca <- as.data.frame(pca_res$x)
  df_pca$lof_score <- scores
  
  p2 <- ggplot(df_pca, aes(x = PC1, y = PC2, color = lof_score)) +
    geom_point(aes(size = lof_score), alpha = 0.5) +
    scale_color_gradient(low = "lightgrey", high = "darkorange") +
    theme_bw() +
    labs(title = "Proyección PCA y LOF Score",
         subtitle = "Los outliers se alejan de la masa de datos")
  
  print(p1 / p2)
  
  # Resumen en consola
  n_outliers <- sum(scores > umbral)
  cat("\n📌 Observaciones con LOF >", umbral, ":", n_outliers,
      "(", round(n_outliers/nrow(datos)*100, 2), "%)\n")
  
  return(datos)
}

