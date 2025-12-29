# Walmart Sales Analytics Project
SQL | Power BI | Python

---

## Project Overview
This project is an end-to-end retail analytics solution built using Walmart weekly sales data.

The goal is to analyze historical sales performance, identify business risks, and build a short-term sales forecasting model, while clearly separating responsibilities across SQL, Power BI, and Python.

---

## Business Objectives
- Analyze revenue distribution across stores and departments
- Identify stores and departments with unstable demand
- Measure holiday impact on weekly sales
- Evaluate store size efficiency
- Assess sensitivity to economic indicators
- Forecast weekly sales for short-term planning

---

## Dataset
Weekly Walmart sales data including:
- Store, Department, Date
- Weekly Sales, Holiday Flag
- Store Type and Store Size
- Economic indicators (CPI, Fuel Price, Unemployment)

---

## SQL: Data Engineering & Business Analysis
- Validated raw data (duplicates, mismatches, sanity checks)
- Created cleaned analytical tables with primary and foreign keys
- Performed backend business analysis:
  - Revenue concentration risk
  - Store-level sales volatility
  - Size-normalized store efficiency
  - Department contribution and demand variability
  - Holiday and economic sensitivity
  - Executive-style store risk classification

SQL focuses on risk, stability, and efficiency, not visualization.

---

## Power BI: Dashboard
Power BI is used for descriptive and diagnostic analysis only.

Key insights:
- Total sales ≈ 6.74B
- Moderate holiday uplift (~7–8%)
- Flat year-over-year growth
- Strong seasonality patterns
- Store Type A dominates revenue
- Limited aggregate impact from economic indicators

### Dashboard File
Download Power BI dashboard:
https://drive.google.com/file/d/1rK4aZ1c3LLGCZ7h0iP_K_hROnHb_xFSS/view?usp=sharing

---

## Dashboard Storytelling Walkthrough
This video explains the dashboard insights as a business narrative, demonstrating how the visuals are interpreted and validated using slicers.

Watch the walkthrough:
https://drive.google.com/file/d/1IOWRpkM0cCUsN6oM5crDvwuFrDvVG3-Q/view?usp=drive_link

---

## Python: Forecasting & Modeling
- Framed as a regression problem (Weekly Sales)
- Built a time-series-aware XGBoost regression pipeline
- Used TimeSeriesSplit to prevent data leakage
- Evaluated using MAE, RMSE, and R²

Model Performance:
- R² ≈ 98%, indicating strong explanatory power on future data
- Generated short-term weekly sales forecasts
- Moving averages used only for smoothing and visualization

---

## Tool Responsibility
Tool        | Purpose
----------- | ---------------------------------------
SQL         | Data validation, business logic, risk analysis
Power BI   | Trends, KPIs, diagnostics
Python     | Forecasting, modeling, evaluation

---

## Limitations
- Short-term forecasting only
- No causal inference
- No confidence intervals

---

## Conclusion
This project demonstrates a production-style analytics workflow that combines SQL, Power BI, and Python without overlap, focusing on correctness, transparency, and business relevance.

---

## Tools Used
SQL Server, Power BI, Python (Pandas, Scikit-learn, XGBoost)

---

## Author
Nandana V Shamjith  
Data Analytics & Business Intelligence Portfolio Project


