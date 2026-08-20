/* =====================================================================
   BANK CUSTOMER TARGETING — MASTER QUERY FILE
   --------------------------------------------------

   ===================================================================== */

/* #####################################################################
   SECTION A — DATA QUALITY & BUSINESS LOGIC CHECKS
   Expected result for the supplied Excel file: all checks = 0 where noted.
   ##################################################################### */

-- A1. Row count and unique customer count
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers
FROM dbo.customer_campaign;

-- Expected: 8,000 rows and 8,000 unique customers.


-- A2. Duplicate Customer IDs
SELECT
    Customer_ID,
    COUNT(*) AS Duplicate_Count
FROM dbo.customer_campaign
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

-- Expected: 0 rows.


-- A3. NULL check for every source field
SELECT
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Null_Customer_ID,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Null_Age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Null_Gender,
    SUM(CASE WHEN Monthly_Income_Million_VND IS NULL THEN 1 ELSE 0 END) AS Null_Income,
    SUM(CASE WHEN Customer_Tenure_Months IS NULL THEN 1 ELSE 0 END) AS Null_Tenure,
    SUM(CASE WHEN Account_Balance_Million_VND IS NULL THEN 1 ELSE 0 END) AS Null_Balance,
    SUM(CASE WHEN App_Logins_Last_30D IS NULL THEN 1 ELSE 0 END) AS Null_App_Logins,
    SUM(CASE WHEN Transactions_Last_30D IS NULL THEN 1 ELSE 0 END) AS Null_Transactions,
    SUM(CASE WHEN Digital_Active_Flag IS NULL THEN 1 ELSE 0 END) AS Null_Digital_Active,
    SUM(CASE WHEN Customer_Segment IS NULL THEN 1 ELSE 0 END) AS Null_Segment,
    SUM(CASE WHEN Campaign_Channel IS NULL THEN 1 ELSE 0 END) AS Null_Channel,
    SUM(CASE WHEN Product_Offered IS NULL THEN 1 ELSE 0 END) AS Null_Product,
    SUM(CASE WHEN Campaign_Exposed_Flag IS NULL THEN 1 ELSE 0 END) AS Null_Exposure,
    SUM(CASE WHEN Clicked_Flag IS NULL THEN 1 ELSE 0 END) AS Null_Clicked,
    SUM(CASE WHEN Converted_Flag IS NULL THEN 1 ELSE 0 END) AS Null_Converted,
    SUM(CASE WHEN Campaign_Cost_Million_VND IS NULL THEN 1 ELSE 0 END) AS Null_Cost,
    SUM(CASE WHEN Revenue_Million_VND IS NULL THEN 1 ELSE 0 END) AS Null_Revenue,
    SUM(CASE WHEN ROI IS NULL THEN 1 ELSE 0 END) AS Null_ROI
FROM dbo.customer_campaign;

-- Expected: all = 0.


-- A4. Flag-domain check (useful if data was imported before CHECK constraints existed)
SELECT
    SUM(CASE WHEN Digital_Active_Flag NOT IN (0,1) THEN 1 ELSE 0 END) AS Invalid_Digital_Flag,
    SUM(CASE WHEN Campaign_Exposed_Flag NOT IN (0,1) THEN 1 ELSE 0 END) AS Invalid_Exposure_Flag,
    SUM(CASE WHEN Clicked_Flag NOT IN (0,1) THEN 1 ELSE 0 END) AS Invalid_Click_Flag,
    SUM(CASE WHEN Converted_Flag NOT IN (0,1) THEN 1 ELSE 0 END) AS Invalid_Conversion_Flag
FROM dbo.customer_campaign;

-- Expected: all = 0.


-- A5. Funnel / campaign business-logic check
SELECT
    SUM(
        CASE
            WHEN Clicked_Flag = 1 AND Campaign_Exposed_Flag = 0
            THEN 1 ELSE 0
        END
    ) AS Clicked_Without_Exposure,

    SUM(
        CASE
            WHEN Converted_Flag = 1 AND Campaign_Exposed_Flag = 0
            THEN 1 ELSE 0
        END
    ) AS Converted_Without_Exposure,

    SUM(
        CASE
            WHEN Converted_Flag = 1 AND Clicked_Flag = 0
            THEN 1 ELSE 0
        END
    ) AS Converted_Without_Click,

    SUM(
        CASE
            WHEN Campaign_Exposed_Flag = 0
             AND Campaign_Cost_Million_VND <> 0
            THEN 1 ELSE 0
        END
    ) AS Cost_Without_Exposure,

    SUM(
        CASE
            WHEN Converted_Flag = 0
             AND Revenue_Million_VND <> 0
            THEN 1 ELSE 0
        END
    ) AS Revenue_Without_Conversion
FROM dbo.customer_campaign;

/* Expected:
   Clicked_Without_Exposure     = 0
   Converted_Without_Exposure  = 0
   Converted_Without_Click     = 0
   Cost_Without_Exposure       = 0
   Revenue_Without_Conversion  = 0
*/


-- A6. Source ranges / sanity checks
SELECT
    MIN(Age) AS Min_Age,
    MAX(Age) AS Max_Age,
    MIN(Monthly_Income_Million_VND) AS Min_Income_M_VND,
    MAX(Monthly_Income_Million_VND) AS Max_Income_M_VND,
    MIN(Customer_Tenure_Months) AS Min_Tenure_Months,
    MAX(Customer_Tenure_Months) AS Max_Tenure_Months,
    MIN(Account_Balance_Million_VND) AS Min_Balance_M_VND,
    MAX(Account_Balance_Million_VND) AS Max_Balance_M_VND,
    MIN(App_Logins_Last_30D) AS Min_App_Logins,
    MAX(App_Logins_Last_30D) AS Max_App_Logins,
    MIN(Transactions_Last_30D) AS Min_Transactions,
    MAX(Transactions_Last_30D) AS Max_Transactions
FROM dbo.customer_campaign;

/* Expected from supplied file:
   Age             18 .. 65
   Income           6 .. 180 M VND
   Tenure           1 .. 120 months
   Balance          0.6 .. 1,500 M VND
   App Logins       1 .. 28
   Transactions     4 .. 38
*/


/* #####################################################################
   SECTION B — EXECUTIVE KPI CARDS
   Dashboard Page 1: Current Campaign Performance
   ##################################################################### */

-- B1. Total Customers
SELECT COUNT(*) AS Total_Customers
FROM dbo.customer_campaign;

-- B2. Exposed Customers
SELECT SUM(CAST(Campaign_Exposed_Flag AS BIGINT)) AS Exposed_Customers
FROM dbo.customer_campaign;

-- B3. Clicked Customers
SELECT SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers
FROM dbo.customer_campaign;

-- B4. Converted Customers
SELECT SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers
FROM dbo.customer_campaign;

-- B5. Exposure Rate (%)
SELECT
    ROUND(
        SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Exposure_Rate_Pct
FROM dbo.customer_campaign;

-- B6. Click Through Rate (%) = Clicked / Exposed
SELECT
    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CTR_Pct
FROM dbo.customer_campaign;

-- B7. Conversion Rate (%) = Converted / Exposed
SELECT
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign;

-- B8. Conversion from Click (%) = Converted / Clicked
SELECT
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Clicked_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS Conversion_From_Click_Pct
FROM dbo.customer_campaign;

-- B9. Total Campaign Cost (Million VND)
SELECT
    ROUND(SUM(Campaign_Cost_Million_VND), 2) AS Total_Campaign_Cost_Million_VND
FROM dbo.customer_campaign;

-- B10. Total Revenue (Million VND)
SELECT
    ROUND(SUM(Revenue_Million_VND), 2) AS Total_Revenue_Million_VND
FROM dbo.customer_campaign;

-- B11. CAC = Total Campaign Cost / Converted Customers
SELECT
    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CAC_Million_VND
FROM dbo.customer_campaign;

-- B12. Overall ROI (%)
-- IMPORTANT: aggregate ROI must be calculated from SUM(Revenue) and SUM(Cost).
-- DO NOT use AVG(ROI).
SELECT
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND), 0),
        2
    ) AS Overall_ROI_Pct
FROM dbo.customer_campaign;


/* #####################################################################
   SECTION C — ONE-ROW EXECUTIVE SUMMARY
   Best query for KPI cards / API / HTML dashboard header.
   ##################################################################### */

SELECT
    COUNT(*) AS Total_Customers,

    SUM(CAST(Campaign_Exposed_Flag AS BIGINT)) AS Exposed_Customers,
    SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,

    ROUND(
        SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Exposure_Rate_Pct,

    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CTR_Pct,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Clicked_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS Conversion_From_Click_Pct,

    ROUND(SUM(Campaign_Cost_Million_VND), 2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND), 2) AS Revenue_Million_VND,

    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CAC_Million_VND,

    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND), 0),
        2
    ) AS Overall_ROI_Pct
FROM dbo.customer_campaign;

/* Expected from supplied Excel:
   Total_Customers               8,000
   Exposed_Customers             5,432
   Clicked_Customers               810
   Converted_Customers             105
   Exposure_Rate_Pct             67.90
   CTR_Pct                       14.91
   Conversion_Rate_Pct            1.93
   Conversion_From_Click_Pct     12.96
   Campaign_Cost_Million_VND   3642.65
   Revenue_Million_VND         8980.00
   CAC_Million_VND               34.69
   Overall_ROI_Pct              146.52
*/


/* #####################################################################
   SECTION D — CAMPAIGN FUNNEL
   Dashboard Page 1 chart.
   ##################################################################### */

SELECT
    1 AS Stage_Order,
    'Total Customers' AS Funnel_Stage,
    COUNT(*) AS Customers
FROM dbo.customer_campaign

UNION ALL

SELECT
    2,
    'Exposed',
    SUM(CAST(Campaign_Exposed_Flag AS BIGINT))
FROM dbo.customer_campaign

UNION ALL

SELECT
    3,
    'Clicked',
    SUM(CAST(Clicked_Flag AS BIGINT))
FROM dbo.customer_campaign

UNION ALL

SELECT
    4,
    'Converted',
    SUM(CAST(Converted_Flag AS BIGINT))
FROM dbo.customer_campaign

ORDER BY Stage_Order;

/* Expected funnel:
   Total Customers  8,000
   Exposed          5,432
   Clicked            810
   Converted          105
*/


/* #####################################################################
   SECTION E — CONVERTED vs NON-CONVERTED
   Target distribution / class imbalance.
   IMPORTANT: evaluate only the exposed population.
   ##################################################################### */

SELECT
    CASE
        WHEN Converted_Flag = 1 THEN 'Converted'
        ELSE 'Not Converted'
    END AS Conversion_Status,

    COUNT(*) AS Customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS Share_Of_Exposed_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Converted_Flag
ORDER BY Converted_Flag DESC;

/* Expected:
   Converted        105   1.93%
   Not Converted  5,327  98.07%
*/


/* #####################################################################
   SECTION F — CUSTOMER SEGMENT ANALYSIS
   Main question: WHO converts better?
   ##################################################################### */

-- F1. Segment population across all customers
SELECT
    Customer_Segment,
    COUNT(*) AS Total_Customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS Population_Share_Pct
FROM dbo.customer_campaign
GROUP BY Customer_Segment
ORDER BY Total_Customers DESC;

/* Actual population:
   Mass Retail      7,372
   Digital Active     546
   High Value          80
   Low Engagement       2
*/


-- F2. Conversion by Customer Segment — exposed only
SELECT
    Customer_Segment,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Customer_Segment
ORDER BY Conversion_Rate_Pct DESC;

/* Actual:
   Digital Active      359 exposed | 16 converted | 4.46%
   High Value           66 exposed |  2 converted | 3.03%
   Mass Retail       5,005 exposed | 87 converted | 1.74%
   Low Engagement        2 exposed |  0 converted | 0.00%

   Caveat: High Value and especially Low Engagement have small samples.
*/


-- F3. Digital Active segment vs Mass Retail conversion lift
WITH segment_conversion AS (
    SELECT
        Customer_Segment,
        SUM(CAST(Converted_Flag AS DECIMAL(18,8)))
            / NULLIF(COUNT(*), 0) AS Conversion_Rate
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
      AND Customer_Segment IN ('Digital Active', 'Mass Retail')
    GROUP BY Customer_Segment
)
SELECT
    ROUND(
        MAX(CASE WHEN Customer_Segment = 'Digital Active' THEN Conversion_Rate END) * 100,
        2
    ) AS Digital_Active_CVR_Pct,

    ROUND(
        MAX(CASE WHEN Customer_Segment = 'Mass Retail' THEN Conversion_Rate END) * 100,
        2
    ) AS Mass_Retail_CVR_Pct,

    ROUND(
        MAX(CASE WHEN Customer_Segment = 'Digital Active' THEN Conversion_Rate END)
        / NULLIF(
            MAX(CASE WHEN Customer_Segment = 'Mass Retail' THEN Conversion_Rate END),
            0
        ),
        2
    ) AS Conversion_Lift
FROM segment_conversion;

-- Expected lift ≈ 2.56x.


/* #####################################################################
   SECTION G — DIGITAL ENGAGEMENT ANALYSIS
   Main finding: recent digital engagement is the clearest behavioural signal.
   ##################################################################### */

-- G1. Digital Active Flag performance — exposed only
SELECT
    Digital_Active_Flag,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,

    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS CTR_Pct,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CAC_Million_VND,

    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND), 0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Digital_Active_Flag
ORDER BY Digital_Active_Flag DESC;

/* Actual:
   Digital_Active_Flag = 1:
      3,309 exposed | 73 conversions | CVR 2.21% | CAC 30.14M | ROI 202.97%
   Digital_Active_Flag = 0:
      2,123 exposed | 32 conversions | CVR 1.51% | CAC 45.09M | ROI 60.46%
*/


-- G2. App Login Band
WITH app_engagement AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN App_Logins_Last_30D BETWEEN 1 AND 5  THEN '1-5'
            WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN '6-10'
            WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN '11-15'
            WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN '16-20'
            WHEN App_Logins_Last_30D >= 21 THEN '21+'
            ELSE 'Other'
        END AS App_Login_Band,
        CASE
            WHEN App_Logins_Last_30D BETWEEN 1 AND 5  THEN 1
            WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN 2
            WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN 3
            WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN 4
            WHEN App_Logins_Last_30D >= 21 THEN 5
            ELSE 6
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    App_Login_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM app_engagement
GROUP BY App_Login_Band, Band_Order
ORDER BY Band_Order;

/* Actual:
   1-5       122 exposed |  2 converted | 1.64%
   6-10    1,719 exposed | 23 converted | 1.34%
   11-15   2,742 exposed | 53 converted | 1.93%
   16-20     782 exposed | 22 converted | 2.81%
   21+        67 exposed |  5 converted | 7.46%

   Important caveat: the 21+ group is small (n=67).
*/


-- G3. Transaction Band
WITH transaction_band AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN Transactions_Last_30D <= 10 THEN '<=10'
            WHEN Transactions_Last_30D BETWEEN 11 AND 15 THEN '11-15'
            WHEN Transactions_Last_30D BETWEEN 16 AND 20 THEN '16-20'
            WHEN Transactions_Last_30D BETWEEN 21 AND 25 THEN '21-25'
            ELSE '26+'
        END AS Transaction_Band,
        CASE
            WHEN Transactions_Last_30D <= 10 THEN 1
            WHEN Transactions_Last_30D <= 15 THEN 2
            WHEN Transactions_Last_30D <= 20 THEN 3
            WHEN Transactions_Last_30D <= 25 THEN 4
            ELSE 5
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    Transaction_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM transaction_band
GROUP BY Transaction_Band, Band_Order
ORDER BY Band_Order;

/* Actual CVR:
   <=10     0.68%
   11-15    1.89%
   16-20    2.17%
   21-25    1.82%
   26+      1.14%
   No strong monotonic relationship.
*/


/* #####################################################################
   SECTION H — DEMOGRAPHIC / FINANCIAL SUPPORTING ANALYSIS
   Purpose: show why simple demographic rules are insufficient.
   All conversion rates use the exposed population only.
   ##################################################################### */

-- H1. Age Band
WITH age_band AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN Age BETWEEN 18 AND 24 THEN '18-24'
            WHEN Age BETWEEN 25 AND 34 THEN '25-34'
            WHEN Age BETWEEN 35 AND 44 THEN '35-44'
            WHEN Age BETWEEN 45 AND 54 THEN '45-54'
            ELSE '55+'
        END AS Age_Band,
        CASE
            WHEN Age BETWEEN 18 AND 24 THEN 1
            WHEN Age BETWEEN 25 AND 34 THEN 2
            WHEN Age BETWEEN 35 AND 44 THEN 3
            WHEN Age BETWEEN 45 AND 54 THEN 4
            ELSE 5
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    Age_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM age_band
GROUP BY Age_Band, Band_Order
ORDER BY Band_Order;

/* Actual CVR:
   18-24  1.40%
   25-34  2.09%
   35-44  2.07%
   45-54  1.73%
   55+    2.22%
   Conclusion: no clear standalone age pattern.
*/


-- H2. Income Band
WITH income_band AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN Monthly_Income_Million_VND <= 15 THEN '<=15M'
            WHEN Monthly_Income_Million_VND <= 25 THEN '15-25M'
            WHEN Monthly_Income_Million_VND <= 35 THEN '25-35M'
            WHEN Monthly_Income_Million_VND <= 50 THEN '35-50M'
            ELSE '>50M'
        END AS Income_Band,
        CASE
            WHEN Monthly_Income_Million_VND <= 15 THEN 1
            WHEN Monthly_Income_Million_VND <= 25 THEN 2
            WHEN Monthly_Income_Million_VND <= 35 THEN 3
            WHEN Monthly_Income_Million_VND <= 50 THEN 4
            ELSE 5
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    Income_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM income_band
GROUP BY Income_Band, Band_Order
ORDER BY Band_Order;

/* Actual CVR:
   <=15M    2.28%
   15-25M   2.02%
   25-35M   2.23%
   35-50M   1.29%
   >50M     1.14%
   Key point: higher income does not automatically imply higher conversion.
*/


-- H3. Account Balance Band
WITH balance_band AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN Account_Balance_Million_VND <= 20 THEN '<=20M'
            WHEN Account_Balance_Million_VND <= 50 THEN '20-50M'
            WHEN Account_Balance_Million_VND <= 100 THEN '50-100M'
            WHEN Account_Balance_Million_VND <= 200 THEN '100-200M'
            ELSE '>200M'
        END AS Balance_Band,
        CASE
            WHEN Account_Balance_Million_VND <= 20 THEN 1
            WHEN Account_Balance_Million_VND <= 50 THEN 2
            WHEN Account_Balance_Million_VND <= 100 THEN 3
            WHEN Account_Balance_Million_VND <= 200 THEN 4
            ELSE 5
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    Balance_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM balance_band
GROUP BY Balance_Band, Band_Order
ORDER BY Band_Order;

/* Actual CVR:
   <=20M       1.75%
   20-50M      2.04%
   50-100M     1.46%
   100-200M    2.22%
   >200M       2.68%
   Relationship is not monotonic.
*/


-- H4. Customer Tenure Band
WITH tenure_band AS (
    SELECT
        Customer_ID,
        Converted_Flag,
        CASE
            WHEN Customer_Tenure_Months <= 12 THEN '<=12 Months'
            WHEN Customer_Tenure_Months <= 36 THEN '13-36 Months'
            WHEN Customer_Tenure_Months <= 60 THEN '37-60 Months'
            WHEN Customer_Tenure_Months <= 90 THEN '61-90 Months'
            ELSE '91-120 Months'
        END AS Tenure_Band,
        CASE
            WHEN Customer_Tenure_Months <= 12 THEN 1
            WHEN Customer_Tenure_Months <= 36 THEN 2
            WHEN Customer_Tenure_Months <= 60 THEN 3
            WHEN Customer_Tenure_Months <= 90 THEN 4
            ELSE 5
        END AS Band_Order
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
)
SELECT
    Tenure_Band,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM tenure_band
GROUP BY Tenure_Band, Band_Order
ORDER BY Band_Order;

/* Actual CVR:
   <=12       1.92%
   13-36      1.59%
   37-60      2.01%
   61-90      2.00%
   91-120     2.07%
   Conclusion: tenure is almost flat as a standalone driver.
*/


-- H5. Gender — descriptive / fairness monitoring only
SELECT
    Gender,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Gender
ORDER BY Conversion_Rate_Pct DESC;


/* #####################################################################
   SECTION I — CHANNEL PERFORMANCE
   Main question: WHERE should the bank reach customers?
   ##################################################################### */

-- I1. Full Channel Performance
SELECT
    Campaign_Channel,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,

    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS CTR_Pct,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(SUM(Campaign_Cost_Million_VND), 2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND), 2) AS Revenue_Million_VND,

    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))), 0),
        2
    ) AS CAC_Million_VND,

    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND), 0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Campaign_Channel
ORDER BY Conversion_Rate_Pct DESC;

/* Actual:
   Branch        n= 622 | CVR 4.18% | CAC  71.77M | ROI  32.10%
   Mobile App    n=1893 | CVR 2.80% | CAC  12.50M | ROI 589.00%
   Email         n=1258 | CVR 1.27% | CAC  15.73M | ROI 412.72%
   SMS           n= 886 | CVR 0.79% | CAC  56.96M | ROI -31.03%
   Social Media  n= 773 | CVR 0.39% | CAC 154.60M | ROI -16.99%

   Key insight:
   highest conversion channel != most economically efficient channel.
*/


-- I2. Channel ranking by ROI
WITH channel_metrics AS (
    SELECT
        Campaign_Channel,
        COUNT(*) AS Customers,
        SUM(CAST(Converted_Flag AS BIGINT)) AS Conversions,
        SUM(Campaign_Cost_Million_VND) AS Campaign_Cost,
        SUM(Revenue_Million_VND) AS Revenue
    FROM dbo.customer_campaign
    WHERE Campaign_Exposed_Flag = 1
    GROUP BY Campaign_Channel
)
SELECT
    Campaign_Channel,
    Customers,
    Conversions,
    ROUND(Conversions * 100.0 / NULLIF(Customers,0), 2) AS Conversion_Rate_Pct,
    ROUND(Campaign_Cost / NULLIF(CAST(Conversions AS DECIMAL(18,4)),0), 2) AS CAC_Million_VND,
    ROUND((Revenue - Campaign_Cost) * 100.0 / NULLIF(Campaign_Cost,0), 2) AS ROI_Pct,
    DENSE_RANK() OVER (
        ORDER BY (Revenue - Campaign_Cost) / NULLIF(Campaign_Cost,0) DESC
    ) AS ROI_Rank
FROM channel_metrics
ORDER BY ROI_Rank, Campaign_Channel;


-- I3. Customer Segment x Channel
-- Use sample size before interpreting small cells.
SELECT
    Customer_Segment,
    Campaign_Channel,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Customer_Segment, Campaign_Channel
ORDER BY Customer_Segment, Conversion_Rate_Pct DESC;


-- I4. Digital Active segment by Channel
SELECT
    Campaign_Channel,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
  AND Customer_Segment = 'Digital Active'
GROUP BY Campaign_Channel
ORDER BY Conversion_Rate_Pct DESC;


/* #####################################################################
   SECTION J — PRODUCT PERFORMANCE
   Main question: WHAT creates conversion vs business value?
   ##################################################################### */

-- J1. Product Performance
SELECT
    Product_Offered,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,

    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,

    ROUND(SUM(Campaign_Cost_Million_VND), 2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND), 2) AS Revenue_Million_VND,

    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))),0),
        2
    ) AS CAC_Million_VND,

    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Product_Offered
ORDER BY ROI_Pct DESC;

/* Actual:
   Insurance        n= 557 | CVR 1.62% | ROI 480.90%
   Personal Loan    n=1097 | CVR 2.01% | ROI 434.45%
   Credit Card      n=1472 | CVR 2.24% | ROI  78.72%
   Savings          n=1226 | CVR 1.63% | ROI -15.34%
   Digital Account  n=1080 | CVR 1.94% | ROI -26.93%

   Key insight: conversion rate != profitability.
*/


-- J2. Channel x Product Matrix
-- Suitable for heatmap / matrix visual. Interpret small n cautiously.
SELECT
    Campaign_Channel,
    Product_Offered,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(SUM(Campaign_Cost_Million_VND), 2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND), 2) AS Revenue_Million_VND,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Campaign_Channel, Product_Offered
ORDER BY Campaign_Channel, ROI_Pct DESC;


/* #####################################################################
   SECTION K — OPTIONAL EDA-BASED PRIORITY RULE
   This is an interpretable BUSINESS HEURISTIC only.
   It is NOT the final propensity model.
   ##################################################################### */

WITH customer_priority AS (
    SELECT
        Customer_ID,
        Campaign_Exposed_Flag,
        Converted_Flag,
        Customer_Segment,
        Digital_Active_Flag,
        App_Logins_Last_30D,
        CASE
            WHEN Customer_Segment = 'Digital Active'
             AND App_Logins_Last_30D >= 16
                THEN 'P1 - High Priority'
            WHEN Digital_Active_Flag = 1
              OR App_Logins_Last_30D >= 16
                THEN 'P2 - Target Selectively'
            WHEN App_Logins_Last_30D BETWEEN 11 AND 15
                THEN 'P3 - Nurture'
            ELSE 'P4 - Lower Priority'
        END AS EDA_Priority
    FROM dbo.customer_campaign
)
SELECT
    EDA_Priority,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Campaign_Exposed_Flag = 1 THEN 1 ELSE 0 END) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(
            SUM(CASE WHEN Campaign_Exposed_Flag = 1 THEN CAST(1 AS DECIMAL(18,4)) ELSE 0 END),
            0
        ),
        2
    ) AS Conversion_Rate_Among_Exposed_Pct
FROM customer_priority
GROUP BY EDA_Priority
ORDER BY EDA_Priority;


/* #####################################################################
   SECTION L — PROPENSITY MODEL FEATURE VIEW

   IMPORTANT T-SQL RULE:
   CREATE OR ALTER VIEW must be the first statement in its batch.
   Therefore GO is required before/after the view in an SSMS-style script.

   Baseline objective = WHO should be targeted?
   Excludes Gender from baseline model for fairness-sensitive use.
   Excludes Channel/Product so the first model is customer propensity only.
   ##################################################################### */
GO
CREATE OR ALTER VIEW dbo.vw_propensity_model_features
AS
SELECT
    Customer_ID,
    Age,
    Monthly_Income_Million_VND,
    Customer_Tenure_Months,
    Account_Balance_Million_VND,
    App_Logins_Last_30D,
    Transactions_Last_30D,
    Digital_Active_Flag,
    Customer_Segment,
    Converted_Flag
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1;
GO


-- L1. Verify modelling population
SELECT
    COUNT(*) AS Modeling_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Positive_Class_Customers,
    COUNT(*) - SUM(CAST(Converted_Flag AS BIGINT)) AS Negative_Class_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Positive_Class_Rate_Pct
FROM dbo.vw_propensity_model_features;

/* Expected:
   Modeling_Customers       = 5,432
   Positive_Class_Customers =   105
   Negative_Class_Customers = 5,327
   Positive_Class_Rate      = 1.93%

   Because the target is highly imbalanced, do not rely on Accuracy alone.
   Prefer ranking/business metrics such as PR-AUC, Recall@K, Lift@K and Gains.
*/


-- L2. Fairness / descriptive audit table kept OUTSIDE the baseline model view
SELECT
    Gender,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Gender;


/* #####################################################################
   SECTION M — MODEL SCORE TABLES

   Python / ML should export the SELECTED model's validated OOF prediction
   for each exposed customer into propensity_scores_oof.

   Each customer must have exactly ONE OOF score from a fold in which that
   customer's target was NOT used for training that prediction.
   ##################################################################### */

IF OBJECT_ID('dbo.propensity_scores_oof', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.propensity_scores_oof (
        Customer_ID          VARCHAR(20)    NOT NULL,
        Actual_Converted     TINYINT        NOT NULL,
        Propensity_Score     DECIMAL(12,10) NOT NULL,
        Fold_ID              INT            NULL,
        Model_Name           VARCHAR(100)   NULL,
        Model_Version        VARCHAR(50)    NULL,

        CONSTRAINT PK_propensity_scores_oof
            PRIMARY KEY (Customer_ID),

        CONSTRAINT FK_propensity_scores_oof_customer
            FOREIGN KEY (Customer_ID)
            REFERENCES dbo.customer_campaign(Customer_ID),

        CONSTRAINT CK_propensity_scores_oof_actual
            CHECK (Actual_Converted IN (0,1)),

        CONSTRAINT CK_propensity_scores_oof_score
            CHECK (Propensity_Score >= 0 AND Propensity_Score <= 1)
    );
END;
GO


/* Final/deployment scores are separated from OOF validation scores.
   These are used to build an actionable target list after model selection.
*/
IF OBJECT_ID('dbo.propensity_scores_final', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.propensity_scores_final (
        Customer_ID          VARCHAR(20)    NOT NULL,
        Propensity_Score     DECIMAL(12,10) NOT NULL,
        Model_Name           VARCHAR(100)   NULL,
        Model_Version        VARCHAR(50)    NULL,
        Scored_At            DATETIME2(0)   NOT NULL
            CONSTRAINT DF_propensity_scores_final_scored_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_propensity_scores_final
            PRIMARY KEY (Customer_ID),

        CONSTRAINT FK_propensity_scores_final_customer
            FOREIGN KEY (Customer_ID)
            REFERENCES dbo.customer_campaign(Customer_ID),

        CONSTRAINT CK_propensity_scores_final_score
            CHECK (Propensity_Score >= 0 AND Propensity_Score <= 1)
    );
END;
GO


/* #####################################################################
   SECTION N — OOF SCORE INTEGRITY CHECKS
   Run after importing Python model outputs.
   ##################################################################### */

-- N1. OOF score count
SELECT
    COUNT(*) AS OOF_Scored_Customers,
    COUNT(DISTINCT Customer_ID) AS Unique_OOF_Customers,
    MIN(Propensity_Score) AS Min_Propensity_Score,
    MAX(Propensity_Score) AS Max_Propensity_Score
FROM dbo.propensity_scores_oof;

-- Expected for full OOF validation population: 5,432 unique customers.


-- N2. Ensure OOF rows correspond only to exposed customers
SELECT
    COUNT(*) AS OOF_Not_Exposed_Count
FROM dbo.propensity_scores_oof p
INNER JOIN dbo.customer_campaign c
    ON p.Customer_ID = c.Customer_ID
WHERE c.Campaign_Exposed_Flag <> 1;

-- Expected: 0.


-- N3. Ensure imported Actual_Converted matches source target
SELECT
    COUNT(*) AS Target_Mismatch_Count
FROM dbo.propensity_scores_oof p
INNER JOIN dbo.customer_campaign c
    ON p.Customer_ID = c.Customer_ID
WHERE p.Actual_Converted <> c.Converted_Flag;

-- Expected: 0.


-- N4. Ensure every exposed customer has an OOF score
SELECT
    COUNT(*) AS Missing_OOF_Score_Count
FROM dbo.customer_campaign c
LEFT JOIN dbo.propensity_scores_oof p
    ON c.Customer_ID = p.Customer_ID
WHERE c.Campaign_Exposed_Flag = 1
  AND p.Customer_ID IS NULL;

-- Expected: 0 after complete scoring.


/* #####################################################################
   SECTION O — OOF CUSTOMER RANKING
   Deterministic tie-breaker = Customer_ID.
   ##################################################################### */

WITH ranked_customers AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        Propensity_Score,

        ROW_NUMBER() OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Propensity_Rank,

        COUNT(*) OVER () AS Total_Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) OVER () AS Total_Conversions
    FROM dbo.propensity_scores_oof
)
SELECT
    Customer_ID,
    Actual_Converted,
    Propensity_Score,
    Propensity_Rank,
    ROUND(
        Propensity_Rank * 100.0 / NULLIF(Total_Customers,0),
        2
    ) AS Population_Rank_Pct
FROM ranked_customers
ORDER BY Propensity_Rank;


/* #####################################################################
   SECTION P — TOP 20% TARGETING VALIDATION
   FINAL BUSINESS TEST

   X = % of total conversions captured
   Y = conversion lift vs full exposed baseline
   Z = % of contact volume not required when only Top 20% are contacted

   IMPORTANT:
   Z is CONTACT-VOLUME REDUCTION, not automatically 80% cost savings.
   Different channels may have different costs, so actual budget savings
   require a channel-specific cost simulation.
   ##################################################################### */

WITH ranked AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        Propensity_Score,

        ROW_NUMBER() OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Propensity_Rank,

        COUNT(*) OVER () AS Total_Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) OVER () AS Total_Conversions
    FROM dbo.propensity_scores_oof
),
top_20 AS (
    SELECT *
    FROM ranked
    WHERE Propensity_Rank <= CEILING(Total_Customers * CAST(0.20 AS DECIMAL(5,2)))
),
metrics AS (
    SELECT
        MAX(Total_Customers) AS Total_Customers,
        MAX(Total_Conversions) AS Total_Conversions,
        COUNT(*) AS Targeted_Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) AS Captured_Conversions
    FROM top_20
)
SELECT
    Total_Customers,
    Targeted_Customers,
    Total_Conversions,
    Captured_Conversions,

    ROUND(
        Targeted_Customers * 100.0 / NULLIF(Total_Customers,0),
        2
    ) AS Population_Targeted_Pct,

    /* X */
    ROUND(
        Captured_Conversions * 100.0 / NULLIF(Total_Conversions,0),
        1
    ) AS Conversions_Captured_Pct,

    ROUND(
        Captured_Conversions * 100.0 / NULLIF(Targeted_Customers,0),
        2
    ) AS Top20_Conversion_Rate_Pct,

    ROUND(
        Total_Conversions * 100.0 / NULLIF(Total_Customers,0),
        2
    ) AS Baseline_Conversion_Rate_Pct,

    /* Y */
    ROUND(
        (
            Captured_Conversions * 1.0 / NULLIF(Targeted_Customers,0)
        )
        /
        NULLIF(
            Total_Conversions * 1.0 / NULLIF(Total_Customers,0),
            0
        ),
        2
    ) AS Conversion_Lift,

    /* Z */
    ROUND(
        (
            1.0
            - Targeted_Customers * 1.0 / NULLIF(Total_Customers,0)
        ) * 100.0,
        1
    ) AS Contact_Volume_Avoided_Pct
FROM metrics;

/* Reference result from the already-validated dashboard model, provided
   the same complete OOF scoring table is loaded:

   Total exposed / OOF customers    = 5,432
   Top-20% target count             = 1,087  (CEILING(5432*0.20))
   Total conversions                =   105
   Captured conversions             =    36
   Conversions captured             = 34.3%
   Conversion lift                  = 1.71x
   Contact volume avoided           = 80.0% (rounded)

   Do not hard-code these values in production SQL. The query above must
   compute them from propensity_scores_oof.
*/


/* #####################################################################
   SECTION Q — DECILE / CUMULATIVE GAINS / LIFT ANALYSIS
   Useful for model validation chart.
   ##################################################################### */

-- Q1. Propensity Deciles
WITH ranked AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        Propensity_Score,
        NTILE(10) OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Propensity_Decile
    FROM dbo.propensity_scores_oof
)
SELECT
    Propensity_Decile,
    COUNT(*) AS Customers,
    SUM(CAST(Actual_Converted AS BIGINT)) AS Conversions,
    ROUND(
        SUM(CAST(Actual_Converted AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(AVG(CAST(Propensity_Score AS DECIMAL(18,10))) * 100.0, 3)
        AS Avg_Predicted_Propensity_Pct
FROM ranked
GROUP BY Propensity_Decile
ORDER BY Propensity_Decile;


-- Q2. Cumulative Gains and Cumulative Lift
WITH ranked AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        NTILE(10) OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Propensity_Decile
    FROM dbo.propensity_scores_oof
),
decile_summary AS (
    SELECT
        Propensity_Decile,
        COUNT(*) AS Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) AS Conversions
    FROM ranked
    GROUP BY Propensity_Decile
),
cumulative AS (
    SELECT
        Propensity_Decile,
        Customers,
        Conversions,
        SUM(Customers) OVER (
            ORDER BY Propensity_Decile
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Customers,
        SUM(Conversions) OVER (
            ORDER BY Propensity_Decile
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Conversions,
        SUM(Customers) OVER () AS Total_Customers,
        SUM(Conversions) OVER () AS Total_Conversions
    FROM decile_summary
)
SELECT
    Propensity_Decile,
    ROUND(
        Cumulative_Customers * 100.0 / NULLIF(Total_Customers,0),
        1
    ) AS Population_Targeted_Pct,
    ROUND(
        Cumulative_Conversions * 100.0 / NULLIF(Total_Conversions,0),
        1
    ) AS Conversions_Captured_Pct,
    ROUND(
        (
            Cumulative_Conversions * 1.0 / NULLIF(Cumulative_Customers,0)
        )
        /
        NULLIF(
            Total_Conversions * 1.0 / NULLIF(Total_Customers,0),
            0
        ),
        2
    ) AS Cumulative_Lift
FROM cumulative
ORDER BY Propensity_Decile;


/* #####################################################################
   SECTION R — MODEL PRIORITY BANDS (OOF / VALIDATION)
   P1 = first 10%
   P2 = next 10% (Top 20% cumulative)
   P3 = next 30% (Top 50% cumulative)
   P4 = remaining 50%
   ##################################################################### */

WITH ranked AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        Propensity_Score,
        ROW_NUMBER() OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Propensity_Rank,
        COUNT(*) OVER () AS Total_Customers
    FROM dbo.propensity_scores_oof
),
priority_customers AS (
    SELECT
        *,
        CASE
            WHEN Propensity_Rank <= CEILING(Total_Customers * CAST(0.10 AS DECIMAL(5,2)))
                THEN 'P1 - First 10%'
            WHEN Propensity_Rank <= CEILING(Total_Customers * CAST(0.20 AS DECIMAL(5,2)))
                THEN 'P2 - Next 10% (Top 20% cumulative)'
            WHEN Propensity_Rank <= CEILING(Total_Customers * CAST(0.50 AS DECIMAL(5,2)))
                THEN 'P3 - Next 30% (Top 50% cumulative)'
            ELSE 'P4 - Remaining 50%'
        END AS Priority
    FROM ranked
)
SELECT
    Priority,
    COUNT(*) AS Customers,
    SUM(CAST(Actual_Converted AS BIGINT)) AS Conversions,
    ROUND(
        SUM(CAST(Actual_Converted AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(
        AVG(CAST(Propensity_Score AS DECIMAL(18,10))) * 100.0,
        3
    ) AS Avg_Propensity_Pct
FROM priority_customers
GROUP BY Priority
ORDER BY
    CASE Priority
        WHEN 'P1 - First 10%' THEN 1
        WHEN 'P2 - Next 10% (Top 20% cumulative)' THEN 2
        WHEN 'P3 - Next 30% (Top 50% cumulative)' THEN 3
        ELSE 4
    END;


/* #####################################################################
   SECTION S — FINAL DEPLOYMENT CUSTOMER TARGET LIST

   Uses propensity_scores_final, NOT OOF scores.
   The score is the model's ranking gate.

   Channel recommendation below is only a BUSINESS HEURISTIC based on
   observed channel economics; it is not a personalised channel-response
   model. A separate Channel / Next-Best-Action model is required before
   claiming individual channel optimality.
   ##################################################################### */

WITH ranked AS (
    SELECT
        p.Customer_ID,
        p.Propensity_Score,
        p.Model_Name,
        p.Model_Version,
        p.Scored_At,
        ROW_NUMBER() OVER (
            ORDER BY p.Propensity_Score DESC, p.Customer_ID ASC
        ) AS Propensity_Rank,
        COUNT(*) OVER () AS Total_Customers
    FROM dbo.propensity_scores_final p
),
customer_targeting AS (
    SELECT
        c.Customer_ID,
        r.Propensity_Score,
        r.Propensity_Rank,
        r.Total_Customers,
        r.Model_Name,
        r.Model_Version,
        r.Scored_At,
        c.Customer_Segment,
        c.Digital_Active_Flag,
        c.App_Logins_Last_30D,
        c.Transactions_Last_30D,
        c.Monthly_Income_Million_VND,
        c.Account_Balance_Million_VND,
        CASE
            WHEN r.Propensity_Rank <= CEILING(r.Total_Customers * CAST(0.10 AS DECIMAL(5,2)))
                THEN 'P1 - Immediate Target'
            WHEN r.Propensity_Rank <= CEILING(r.Total_Customers * CAST(0.20 AS DECIMAL(5,2)))
                THEN 'P2 - Target'
            WHEN r.Propensity_Rank <= CEILING(r.Total_Customers * CAST(0.50 AS DECIMAL(5,2)))
                THEN 'P3 - Nurture'
            ELSE 'P4 - Low Priority'
        END AS Priority
    FROM ranked r
    INNER JOIN dbo.customer_campaign c
        ON r.Customer_ID = c.Customer_ID
)
SELECT
    Customer_ID,
    ROUND(Propensity_Score * 100.0, 2) AS Propensity_Score_Pct,
    Propensity_Rank,
    Priority,
    Customer_Segment,
    Digital_Active_Flag,
    App_Logins_Last_30D,
    Transactions_Last_30D,
    Monthly_Income_Million_VND,
    Account_Balance_Million_VND,
    CASE
        WHEN Priority IN ('P1 - Immediate Target', 'P2 - Target')
         AND Digital_Active_Flag = 1
            THEN 'Mobile App (business heuristic)'
        WHEN Priority IN ('P1 - Immediate Target', 'P2 - Target')
            THEN 'Mobile App / Email (business heuristic)'
        WHEN Priority = 'P3 - Nurture'
            THEN 'Digital Nurture'
        ELSE 'No Immediate Campaign'
    END AS Recommended_Channel_Action,
    Model_Name,
    Model_Version,
    Scored_At
FROM customer_targeting
ORDER BY Propensity_Rank;


/* #####################################################################
   SECTION T — REUSABLE DASHBOARD VIEWS
   These can feed the HTML dashboard directly.
   NOTE: ORDER BY belongs in the consuming SELECT, not inside a normal view.
   ##################################################################### */

GO
CREATE OR ALTER VIEW dbo.vw_dashboard_campaign_overview
AS
SELECT
    COUNT(*) AS Total_Customers,
    SUM(CAST(Campaign_Exposed_Flag AS BIGINT)) AS Exposed_Customers,
    SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Exposure_Rate_Pct,
    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))),0),
        2
    ) AS CTR_Pct,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(SUM(CAST(Campaign_Exposed_Flag AS DECIMAL(18,4))),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(SUM(Campaign_Cost_Million_VND),2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND),2) AS Revenue_Million_VND,
    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))),0),
        2
    ) AS CAC_Million_VND,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS Overall_ROI_Pct
FROM dbo.customer_campaign;
GO


CREATE OR ALTER VIEW dbo.vw_dashboard_segment_performance
AS
SELECT
    Customer_Segment,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Customer_Segment;
GO


CREATE OR ALTER VIEW dbo.vw_dashboard_app_engagement
AS
SELECT
    CASE
        WHEN App_Logins_Last_30D BETWEEN 1 AND 5 THEN '1-5'
        WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN '6-10'
        WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN '11-15'
        WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN '16-20'
        WHEN App_Logins_Last_30D >= 21 THEN '21+'
        ELSE 'Other'
    END AS App_Login_Band,
    CASE
        WHEN App_Logins_Last_30D BETWEEN 1 AND 5 THEN 1
        WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN 2
        WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN 3
        WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN 4
        WHEN App_Logins_Last_30D >= 21 THEN 5
        ELSE 6
    END AS Band_Order,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY
    CASE
        WHEN App_Logins_Last_30D BETWEEN 1 AND 5 THEN '1-5'
        WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN '6-10'
        WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN '11-15'
        WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN '16-20'
        WHEN App_Logins_Last_30D >= 21 THEN '21+'
        ELSE 'Other'
    END,
    CASE
        WHEN App_Logins_Last_30D BETWEEN 1 AND 5 THEN 1
        WHEN App_Logins_Last_30D BETWEEN 6 AND 10 THEN 2
        WHEN App_Logins_Last_30D BETWEEN 11 AND 15 THEN 3
        WHEN App_Logins_Last_30D BETWEEN 16 AND 20 THEN 4
        WHEN App_Logins_Last_30D >= 21 THEN 5
        ELSE 6
    END;
GO


CREATE OR ALTER VIEW dbo.vw_dashboard_channel_performance
AS
SELECT
    Campaign_Channel,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Clicked_Flag AS BIGINT)) AS Clicked_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Clicked_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS CTR_Pct,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(SUM(Campaign_Cost_Million_VND),2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND),2) AS Revenue_Million_VND,
    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))),0),
        2
    ) AS CAC_Million_VND,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Campaign_Channel;
GO


CREATE OR ALTER VIEW dbo.vw_dashboard_product_performance
AS
SELECT
    Product_Offered,
    COUNT(*) AS Exposed_Customers,
    SUM(CAST(Converted_Flag AS BIGINT)) AS Converted_Customers,
    ROUND(
        SUM(CAST(Converted_Flag AS DECIMAL(18,4))) * 100.0
        / NULLIF(COUNT(*),0),
        2
    ) AS Conversion_Rate_Pct,
    ROUND(SUM(Campaign_Cost_Million_VND),2) AS Campaign_Cost_Million_VND,
    ROUND(SUM(Revenue_Million_VND),2) AS Revenue_Million_VND,
    ROUND(
        SUM(Campaign_Cost_Million_VND)
        / NULLIF(SUM(CAST(Converted_Flag AS DECIMAL(18,4))),0),
        2
    ) AS CAC_Million_VND,
    ROUND(
        (
            SUM(Revenue_Million_VND)
            - SUM(Campaign_Cost_Million_VND)
        ) * 100.0
        / NULLIF(SUM(Campaign_Cost_Million_VND),0),
        2
    ) AS ROI_Pct
FROM dbo.customer_campaign
WHERE Campaign_Exposed_Flag = 1
GROUP BY Product_Offered;
GO


/* #####################################################################
   SECTION U — FINAL PRESENTATION KPIs
   The three model numbers management needs.
   Computed only from OOF predictions.
   ##################################################################### */

WITH ranked AS (
    SELECT
        Customer_ID,
        Actual_Converted,
        Propensity_Score,
        ROW_NUMBER() OVER (
            ORDER BY Propensity_Score DESC, Customer_ID ASC
        ) AS Rank_No,
        COUNT(*) OVER () AS Total_Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) OVER () AS Total_Conversions
    FROM dbo.propensity_scores_oof
),
top20 AS (
    SELECT *
    FROM ranked
    WHERE Rank_No <= CEILING(Total_Customers * CAST(0.20 AS DECIMAL(5,2)))
),
summary AS (
    SELECT
        MAX(Total_Customers) AS Total_Customers,
        MAX(Total_Conversions) AS Total_Conversions,
        COUNT(*) AS Targeted_Customers,
        SUM(CAST(Actual_Converted AS BIGINT)) AS Captured_Conversions
    FROM top20
)
SELECT
    /* KPI 1 */
    ROUND(
        Captured_Conversions * 100.0 / NULLIF(Total_Conversions,0),
        1
    ) AS Top20_Conversions_Captured_Pct,

    /* KPI 2 */
    ROUND(
        (
            Captured_Conversions * 1.0 / NULLIF(Targeted_Customers,0)
        )
        /
        NULLIF(
            Total_Conversions * 1.0 / NULLIF(Total_Customers,0),
            0
        ),
        2
    ) AS Conversion_Lift,

    /* KPI 3 */
    ROUND(
        (
            1.0
            - Targeted_Customers * 1.0 / NULLIF(Total_Customers,0)
        ) * 100.0,
        1
    ) AS Contact_Volume_Avoided_Pct
FROM summary;

/* With the current validated OOF score set used by the dashboard:
   Top20_Conversions_Captured_Pct = 34.3
   Conversion_Lift                = 1.71
   Contact_Volume_Avoided_Pct     = 80.0
*/


/* =====================================================================
   FINAL BUSINESS STORY
   =====================================================================

   1) CURRENT CAMPAIGN
      5,432 customers exposed
      -> 810 clicked
      -> 105 converted
      -> baseline exposed conversion = 1.93%

   2) CUSTOMER INSIGHT
      Digital engagement is the clearest customer-level signal.
      Digital Active segment = 4.46% vs Mass Retail = 1.74%.
      Customers with 21+ app logins show 7.46% conversion, but n=67.

   3) DEMOGRAPHIC / FINANCIAL INSIGHT
      Age, tenure, income and transaction count do not show a strong,
      simple monotonic relationship with conversion.

   4) CHANNEL INSIGHT
      Branch has the highest conversion rate (4.18%), but Mobile App
      provides much stronger economics (ROI ~589%, CAC ~12.50M VND).

   5) PRODUCT INSIGHT
      Conversion != profitability.
      Credit Card leads conversion volume, while Insurance / Personal Loan
      show stronger ROI in this synthetic campaign.

   6) PROPENSITY MODEL
      SQL prepares leakage-safe features.
      Python generates validated OOF probabilities.
      SQL ranks customers and measures business concentration.

   7) FINAL VALIDATION
      Target only the highest-ranked 20%:
         -> 34.3% of conversions captured
         -> 1.71x conversion lift
         -> ~80% of contact volume avoided

      IMPORTANT:
      80% contact-volume reduction is NOT automatically 80% cost savings.
      Actual cost savings depend on which channels would otherwise be used.

   8) BUSINESS RECOMMENDATION
      Shift from broad-based marketing toward data-driven customer
      prioritisation, then apply channel/product economics as a second
      decision layer.

   ===================================================================== */
