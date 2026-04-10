# NCR Ride Sharing — Exploratory Data Analysis & Data Cleaning

## Overview
End-to-end data quality analysis of 150,000 ride-sharing bookings from the NCR region (India). The project covers the full EDA and cleaning pipeline, 
from raw data ingestion to a documented, analysis-ready dataset.

## Dataset
- **Source**: [NCR Ride Bookings — Kaggle](https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard)
- **Size**: 150,000 records × 21 variables
- **Domain**: Ride-sharing operations (bookings, cancellations, ratings, pricing)

## What's covered

**Data cleaning**
- Detection and removal of non-standard null values stored as strings
- Escaped quote removal in ID fields
- Type casting of numeric variables stored as characters
- Binary encoding of cancellation and incomplete ride flags

**Duplicate analysis**
- Exact row duplicates
- Duplicate Booking IDs (1,224 IDs → 2,457 affected records)
- Logical duplicates by customer + date + time + location

**Missing value analysis**
- Global missing rate: 11.2%
- MNAR structural pattern: missing values in non-completed rides
- MNAR behavioural pattern: optional customer ratings in completed rides
- No imputation applied where values are structurally absent

**Outlier detection**
- Univariate: IQR method (Tukey rule, coef = 1.5 and 3)
- Multivariate: Local Outlier Factor (LOF) with k = log(n)
- PCA projection for visual validation of outlier candidates

## Results
All 150,000 records preserved. Three indicator variables added:
`id_duplicado`, `rating_provided`, `es_outlier_lof`.

## Tech stack
- **Language**: R
- **Report**: Quarto (.qmd → HTML)
- **Libraries**: tidyverse, naniar, DataExplorer, dbscan, patchwork, janitor, hms, readr, class

## Report(html)
👉 -->  [View full analysis]((https://lorenadata.github.io/ncr-ride-sharing-eda/))

## Project structure
\```
ncr-ride-sharing-eda --> ncr_ride_bookings.csv
R --> Funciones_propias.R
--> ncr_eda_cleaning.qmd
--> ncr_eda_cleaning.html
--> README.md
\```

## Author
**Lorena Marcos** — Data Science student at Universidad Complutense de Madrid.  
[LinkedIn](https://www.linkedin.com/in/lorena-marcos-6516272b5/) · 
[GitHub](https://github.com/Lorenadata)
