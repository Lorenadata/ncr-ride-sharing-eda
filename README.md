# Ride-Sharing Data Quality & Anomaly Detection

[![Report](https://img.shields.io/badge/report-live-2ea44f)](https://lorenadata.github.io/ncr-ride-sharing-eda/)
![R](https://img.shields.io/badge/R-276DC3?logo=r&logoColor=white)
![Quarto](https://img.shields.io/badge/Quarto-75AADB?logo=quarto&logoColor=white)

End-to-end data quality audit of **150,000 ride-sharing bookings** from the NCR region (India): from the raw export to a documented, analysis-ready dataset. No rows were dropped; every issue is flagged instead.

**📄 Full report (Spanish):** https://lorenadata.github.io/ncr-ride-sharing-eda/

---

## Highlights

| Check | Result |
|---|---|
| Records × variables | 150,000 × 21 |
| Duplicate booking IDs | 1,224 IDs → 2,457 affected records |
| Global missing rate | 11.2%, mostly **MNAR** (structural) |
| Univariate outliers | IQR / Tukey fences (k = 1.5 and 3) |
| Multivariate outliers | Local Outlier Factor, k = log(n), validated on a PCA projection |

## What's covered

**1. Cleaning.** Non-standard nulls stored as strings, escaped quotes in IDs, numeric columns stored as text, and binary encoding of cancellation and incomplete-ride flags.

**2. Duplicates.** Exact row duplicates, repeated booking IDs, and *logical* duplicates (same customer, date, time and location).

**3. Missing values.** I identified two distinct **MNAR** mechanisms and did not impute them blindly:
- *Structural:* the ride never happened, so fields like distance or fare can't exist.
- *Behavioural:* customer ratings are optional, even on completed rides.

**4. Outliers.** IQR rules per variable, then LOF on the scaled numeric space to catch observations that are only anomalous in combination.

## Output

All 150,000 records are kept, with three indicator columns added so that downstream users decide what to exclude:

| Column | Meaning |
|---|---|
| `id_duplicado` | Booking ID appears more than once |
| `rating_provided` | Customer left a rating |
| `es_outlier_lof` | Flagged as a multivariate outlier by LOF |

## Repository structure

```
.
├── ncr_ride_sharing_eda.qmd   # Analysis source (Quarto)
├── Funciones_propias.R        # Helper functions (IQR outliers, bivariate plots, LOF)
└── index.html                 # Rendered report, served by GitHub Pages
```

## Reproduce

1. Download `ncr_ride_bookings.csv` from [Kaggle](https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard) into `archive/`.
2. Install the dependencies:
   ```r
   install.packages(c("tidyverse", "naniar", "DataExplorer", "dbscan",
                      "patchwork", "janitor", "hms", "class"))
   ```
3. Render `ncr_ride_sharing_eda.qmd` with Quarto.

---

**Lorena Marcos** · Applied Data Science, Universidad Complutense de Madrid · [LinkedIn](https://www.linkedin.com/in/lorena-marcos-6516272b5/) · [GitHub](https://github.com/Lorenadata)
