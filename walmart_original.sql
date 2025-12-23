--Check duplicates in store_original

SELECT 
    Store,
    COUNT(*) AS cnt
FROM stores_original
GROUP BY Store
HAVING COUNT(*) > 1;

SELECT 
    Store,
    Date,
    COUNT(*) AS cnt
FROM features_original
GROUP BY Store, Date
HAVING COUNT(*) > 1;

SELECT 
    Store,
    Dept,
    Date,
    COUNT(*) AS cnt
FROM train_original
GROUP BY Store, Dept, Date
HAVING COUNT(*) > 1;


--Check Store mismatches (train vs store)
SELECT DISTINCT t.Store
FROM train_original t
LEFT JOIN stores_original s
    ON t.Store = s.Store
WHERE s.Store IS NULL;

-- Check Feature mismatches (train vs feature)
SELECT DISTINCT t.Store, t.Date
FROM train_original t
LEFT JOIN features_original f
    ON t.Store = f.Store
   AND t.Date = f.Date
WHERE f.Store IS NULL;

--Sales sanity check (important)
SELECT 
    MIN(Weekly_Sales) AS min_sales,
    MAX(Weekly_Sales) AS max_sales
FROM train_original;

-- create store
CREATE TABLE stores_cleaned_original (
    Store INT NOT NULL,
    Type CHAR(1) NOT NULL,
    Size INT NOT NULL
);

INSERT INTO stores_cleaned_original (Store, Type, Size)
SELECT 
    Store,
    Type,
    Size
FROM stores_original;

SELECT TOP 10 * FROM stores_cleaned_original;

-- create features
CREATE TABLE features_cleaned_original (
    Store INT NOT NULL,
    Date DATE NOT NULL,
    IsHoliday BIT NOT NULL,
    Temperature DECIMAL(5,2) NULL,
    Fuel_Price DECIMAL(6,3) NULL,
    CPI DECIMAL(6,3) NULL,
    Unemployment DECIMAL(5,2) NULL,
    MarkDown1 DECIMAL(10,2) NULL,
    MarkDown2 DECIMAL(10,2) NULL,
    MarkDown3 DECIMAL(10,2) NULL,
    MarkDown4 DECIMAL(10,2) NULL,
    MarkDown5 DECIMAL(10,2) NULL
);

INSERT INTO features_cleaned_original
SELECT
    Store,
    Date,
    IsHoliday,
    Temperature,
    Fuel_Price,
    CPI,
    Unemployment,
    MarkDown1,
    MarkDown2,
    MarkDown3,
    MarkDown4,
    MarkDown5
FROM features_original;

SELECT TOP 10 * FROM features_cleaned_original;

--create train
CREATE TABLE train_cleaned_original (
    Store INT NOT NULL,
    Dept INT NOT NULL,
    Date DATE NOT NULL,
    Weekly_Sales DECIMAL(18,10) NOT NULL,
    IsHoliday BIT NOT NULL
);

INSERT INTO train_cleaned_original
SELECT
    Store,
    Dept,
    Date,
    Weekly_Sales,
    IsHoliday
FROM train_original;

-- adding primary keys

ALTER TABLE stores_cleaned_original
ADD CONSTRAINT PK_stores_cleaned
PRIMARY KEY (Store);

ALTER TABLE features_cleaned_original
ADD CONSTRAINT PK_features_cleaned
PRIMARY KEY (Store, Date);

ALTER TABLE train_cleaned_original
ADD CONSTRAINT PK_train_cleaned
PRIMARY KEY (Store, Dept, Date);

-- foreign key

ALTER TABLE train_cleaned_original
ADD CONSTRAINT FK_train_stores_cleaned_original
FOREIGN KEY (Store)
REFERENCES stores_cleaned_original (Store);

ALTER TABLE train
ADD CONSTRAINT FK_train_features_cleaned_original
FOREIGN KEY (Store, Date)
REFERENCES features_cleaned_original (Store, Date);

--1.Revenue Dependency Risk (NOT a simple top-N)

--“How dependent are we on a small group of stores?”
WITH store_revenue AS (
    SELECT Store, SUM(Weekly_Sales) AS revenue
    FROM train_cleaned_original
    GROUP BY Store
),
ranked AS (
    SELECT *,
           NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM store_revenue
)
SELECT
    decile,
    COUNT(*) AS store_count,
    SUM(revenue) AS decile_revenue,
    SUM(revenue) * 1.0 / SUM(SUM(revenue)) OVER () AS revenue_share
FROM ranked
GROUP BY decile
ORDER BY decile;

--"If top 10% stores generate 50–60% revenue, business is fragile"
--insight
--Top decile (≈ top 10% stores) contributes ~21.5% of total revenue
--Top 3 deciles together contribute ~53–55% of revenue
-- Bottom deciles contribute very small shares individually (~2–5%)

--2.Store Sales Stability Classification (NOT a trend chart)
--Which stores are predictable vs risky
SELECT
    Store,
    AVG(Weekly_Sales) AS avg_sales,
    STDEV(Weekly_Sales) AS volatility,
    STDEV(Weekly_Sales) / NULLIF(AVG(Weekly_Sales),0) AS volatility_ratio
FROM train_cleaned_original
GROUP BY Store
ORDER BY volatility_ratio DESC;

--insights
--Several stores have volatility ratio > 1.5
--Sales fluctuate more than their average level

--3Store Size Efficiency (Normalized Performance)
--“Are big stores actually efficient?”

SELECT
    s.Store,
    s.Size,
    SUM(t.Weekly_Sales) / NULLIF(s.Size,0) AS sales_per_sqft
FROM train_cleaned_original t
JOIN stores_cleaned_original s
    ON t.Store = s.Store
GROUP BY s.Store, s.Size
ORDER BY sales_per_sqft DESC;
--insights
--Smaller / mid-sized stores appear at the top
--Several large stores rank lower
--Store size ≠ efficiency

--4.Department Revenue Concentration (Strategic Risk)
--“Are we too dependent on a few departments?”

WITH dept_rev AS (
    SELECT Dept, SUM(Weekly_Sales) AS revenue
    FROM train_cleaned_original
    GROUP BY Dept
)
SELECT
    Dept,
    revenue,
    revenue * 1.0 / SUM(revenue) OVER () AS revenue_share
FROM dept_rev
ORDER BY revenue DESC;
--insight
--A few departments individually contribute 5–7% of total revenue
--Long tail of departments each contributes <2%

--5.Department Demand Volatility (Inventory Risk)
--“Which departments are hardest to plan inventory for?”

SELECT
    Dept,
    STDEV(Weekly_Sales) AS demand_variability
FROM train_cleaned_original
GROUP BY Dept
ORDER BY demand_variability DESC;

-- insights
--Certain departments have very high standard deviation
--These departments overlap with:
      --Promotional categories
      --Seasonal categories

--6.Holiday Sensitivity by Store (ADVANCED, not basic)
--“Which stores benefit from holidays and which don’t?”

SELECT
    Store,
    AVG(CASE WHEN IsHoliday = 1 THEN Weekly_Sales END) AS holiday_avg,
    AVG(CASE WHEN IsHoliday = 0 THEN Weekly_Sales END) AS non_holiday_avg,
    AVG(CASE WHEN IsHoliday = 1 THEN Weekly_Sales END)
      - AVG(CASE WHEN IsHoliday = 0 THEN Weekly_Sales END) AS holiday_lift
FROM train_cleaned_original
GROUP BY Store
HAVING AVG(CASE WHEN IsHoliday = 1 THEN Weekly_Sales END) IS NOT NULL;

-- insights
--Holiday lift varies significantly by store
--stores gain ₹1,000–3,000+ per week
-- stores show minimal or negative lift


--7.Economic Sensitivity (CPI impact)

--“Do some stores suffer more during high inflation?”

WITH cpi_flag AS (
    SELECT
        t.Store,
        t.Weekly_Sales,
        CASE
            WHEN f.CPI >= (SELECT AVG(CPI) FROM features_cleaned_original)
            THEN 'High CPI'
            ELSE 'Low CPI'
        END AS cpi_level
    FROM train_cleaned_original t
    JOIN features_cleaned_original f
      ON t.Store = f.Store AND t.Date = f.Date
)
SELECT
    Store,
    cpi_level,
    AVG(Weekly_Sales) AS avg_sales
FROM cpi_flag
GROUP BY Store, cpi_level
ORDER BY Store;
--insights
--Many stores perform worse during High CPI periods
-- stores are relatively CPI-resilient


--8.Executive Store Risk Classification (SQL-only)
--“Which stores need intervention?”

WITH stats AS (
    SELECT
        Store,
        SUM(Weekly_Sales) AS revenue,
        STDEV(Weekly_Sales) / NULLIF(AVG(Weekly_Sales),0) AS volatility
    FROM train_cleaned_original
    GROUP BY Store
)
SELECT
    Store,
    revenue,
    volatility,
    CASE
        WHEN volatility >= 1 THEN 'High Risk'
        WHEN volatility >= 0.5 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM stats
ORDER BY revenue DESC;
--insights
--Many stores classified as High Risk
--High risk = combination of:
--High volatility
--High revenue exposure
