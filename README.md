# Heat Exposure and Maternal Psychosocial Stress in Ghana

Analysis code for the study *"Heat Exposure and Maternal Psychosocial Stress: Evidence
from the GRAPHS Pregnancy Cohort in Ghana"* (CRiSYS-R / GRAPHS).

This repository contains the statistical analysis pipeline used to link daily Wet Bulb
Globe Temperature (WBGT) exposure during pregnancy to maternal psychosocial stress
(CRiSYS-R Negative Domain Score), using ordinal logistic regression and distributed
lag non-linear models (DLNMs).

> **Note on reproducibility:** The individual-level GRAPHS data used in this study are
> not included in this repository. They contain identifiable information from a cohort
> governed by IRB/ethics restrictions and are available only upon reasonable request
> (see **Data availability** below). The code is shared so the full analytic workflow
> is transparent and inspectable.

---

## Repository structure

```
├── README.md
├── .gitignore
├── crisys-heat-maternal-stress.Rproj   # open this so here() resolves to the repo root
├── data_cleaning/
│   ├── clean_stress_data.R             # CRiSYS-R cleaning, Negative Domain Score
│   └── clean_crysis_short_form.R       # short-form CRiSYS + BMI covariate join
├── analysis/
│   ├── tables_and_figures_dlnm_wbgt_peer_rev_edits.Rmd  # PRIMARY analysis: trimester
│   │                                     #   models, DLNMs, all manuscript + supp
│   │                                     #   tables/figures (post-peer-review version)
│   ├── model_selection.Rmd             # DLNM spline specification screen (BIC + visual)
│   ├── heat_index_sensitivity.Rmd      # sensitivity: heat index (HI)
│   ├── t2mC_sensitivity.Rmd            # sensitivity: 2 m air temperature (T2m)
│   ├── WBT_sensitivity.Rmd             # sensitivity: wet-bulb temperature (Tw)
│   └── temp_metric_comparison.Rmd      # comparison of heat metrics
├── data/                               # NOT tracked — you must supply (see below)
└── outputs/                            # generated tables/figures written here
```

Paths in the code use the [`here`](https://here.r-lib.org/) package, which anchors to the repository root (the folder containing the `.Rproj`). Open the project via the `.Rproj` file (or ensure your working directory is the repo root) so all relative paths resolve correctly.

---

## Data availability

The analysis depends on GRAPHS cohort data that cannot be publicly distributed. To run the pipeline, place the following files in a local `data/` directory (git-ignored):

| File | Contents |
|------|----------|
| `alldata_clean_for_bw_19May08.csv` | Participant covariates (age, BMI, SES, parity, etc.) |
| `Stress_NLE.dta` | CRiSYS-R life-events / stress responses |
| `CAL_stress.xlsx` | Additional stress questionnaire data |
| `GRAPHS_datdeliv_vname.csv` | Delivery dates / gestational timing |
| `Community Centroids GRAPHS- CommunityCentroids_MM_DM_revised_10312023.csv` | Community centroids for ERA5 grid-cell matching |
| `GRAPHS-ERA5-CHIRPS/GRAPHS-CHIRPS-Precip.csv` | CHIRPS precipitation series |
| `GRAPHS-ERA5-CHIRPS/GRAPHS-ERA5-Heatstress-Tw-1991missing.csv` | ERA5-derived heat-stress / WBGT series |

De-identified data and a data dictionary are available upon reasonable request
beginning at publication. Requests should be directed to [corresponding author /
GRAPHS data governance contact].

Meteorological source data (ERA5) are freely available from the Copernicus Climate
Data Store:
https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels

---

## Exposure derivation

Daily WBGT was estimated from hourly ERA5 2 m temperature and dewpoint by (1) computing
relative humidity, (2) computing the U.S. National Weather Service heat index, and
(3) applying the Bernard & Iheanacho (2015) quadratic transformation to obtain shaded
WBGT (no direct solar radiation; fixed wind speed 0.5 m/s). See the manuscript Methods
for full detail and references.

---

## How to run

1. Install R (this analysis used **R 4.3.1**).
2. Open `crisys-heat-maternal-stress.Rproj` in RStudio (sets the working directory to
   the repo root so `here()` works).
3. Obtain the data (see **Data availability**) and place the files in `data/`.
4. Knit or run the cleaning scripts first, then the analysis documents. The primary
   analysis lives in `analysis/tables_and_figures_dlnm_wbgt_peer_rev_edits.Rmd`;
   the other `.Rmd`s cover model selection and alternative-metric sensitivity analyses.
   Generated tables and figures are written to `outputs/`.

Key packages: `dlnm`, `MASS`, `splines`, `tidyverse`, `here`, `broom`, `gt`, `gtsummary`.

---
