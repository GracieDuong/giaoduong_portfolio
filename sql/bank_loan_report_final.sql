/*
Credit Risk Portfolio Analytics

Dataset: financial_loan.csv
Table: dbo.financial_loan_database

Skills used:
- Aggregate Functions
- CASE WHEN
- CTEs
- Window Functions
- Risk Segmentation
- Credit Risk KPI Monitoring

Business Objective:
Analyze loan portfolio performance, identify high-risk borrower segments,
and monitor monthly credit risk drift.

Key Assumptions:
- Good Loan = Fully Paid or Current
- Bad Loan = Charged Off
- issue_date = loan origination date
- Dataset does not include DPD, repayment schedule, or monthly loan snapshots.
  Therefore, bad loan rate, recovery ratio, and issue-month trend are used as proxy indicators
  for portfolio risk monitoring.
*/


/* =========================================================
   1. VIEW RAW DATA
   ========================================================= */
   USE [Bank Loan Database];
GO

/* =========================================================
   2. DATA QUALITY CHECK
   ========================================================= */

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT id) AS unique_loan_ids,

    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS missing_id,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) AS missing_loan_amount,
    SUM(CASE WHEN total_payment IS NULL THEN 1 ELSE 0 END) AS missing_total_payment,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS missing_loan_status,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) AS missing_issue_date,

    COUNT(*) - COUNT(DISTINCT id) AS duplicate_loan_id_count
FROM dbo.financial_loan_database;



/* =========================================================
   3. PORTFOLIO KPI SUMMARY
   ========================================================= */

SELECT
    COUNT(id) AS total_loan_applications,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,

    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti,

    SUM(CASE 
        WHEN loan_status IN ('Fully Paid', 'Current') 
        THEN 1 ELSE 0 
    END) AS good_loan_count,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loan_count,

    SUM(CASE 
        WHEN loan_status IN ('Fully Paid', 'Current') 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS good_loan_rate,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    SUM(total_payment) * 1.0 / NULLIF(SUM(loan_amount), 0) AS recovery_ratio
FROM dbo.financial_loan_database;



/* =========================================================
   4. GOOD LOAN VS BAD LOAN SUMMARY
   ========================================================= */

SELECT
    CASE
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
        ELSE 'Other'
    END AS loan_quality,

    COUNT(id) AS loan_count,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,

    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti,

    SUM(total_payment) * 1.0 / NULLIF(SUM(loan_amount), 0) AS recovery_ratio
FROM dbo.financial_loan_database
GROUP BY
    CASE
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
        ELSE 'Other'
    END;



/* =========================================================
   5. CREATE RISK FEATURES WITH CTE
   ========================================================= */

WITH loan_features AS (
    SELECT
        id,
        loan_status,
        loan_amount,
        total_payment,
        int_rate,
        dti,
        issue_date,
        grade,
        sub_grade,
        term,
        purpose,
        home_ownership,
        annual_income,
        emp_length,

        CASE
            WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
            WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
            ELSE 'Other'
        END AS loan_quality,

        CASE
            WHEN loan_status = 'Charged Off' THEN 1
            ELSE 0
        END AS bad_loan_flag,

        CASE
            WHEN dti < 0.10 THEN 'Low DTI'
            WHEN dti < 0.20 THEN 'Medium DTI'
            ELSE 'High DTI'
        END AS dti_band,

        CASE
            WHEN int_rate < 0.10 THEN 'Low Interest'
            WHEN int_rate < 0.15 THEN 'Medium Interest'
            ELSE 'High Interest'
        END AS interest_rate_band,

        CASE
            WHEN loan_amount < 5000 THEN 'Small Loan'
            WHEN loan_amount < 15000 THEN 'Medium Loan'
            ELSE 'Large Loan'
        END AS loan_amount_band,

        CASE
            WHEN annual_income < 40000 THEN 'Low Income'
            WHEN annual_income < 80000 THEN 'Medium Income'
            ELSE 'High Income'
        END AS income_band,

        total_payment * 1.0 / NULLIF(loan_amount, 0) AS recovery_ratio
    FROM dbo.financial_loan_database
)

SELECT *
FROM loan_features;



/* =========================================================
   6. BAD LOAN RATE BY CREDIT GRADE
   ========================================================= */

SELECT
    grade,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received
FROM dbo.financial_loan_database
GROUP BY grade
ORDER BY grade;



/* =========================================================
   7. BAD LOAN RATE BY TERM
   ========================================================= */

SELECT
    term,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,
    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti
FROM dbo.financial_loan_database
GROUP BY term
ORDER BY term;



/* =========================================================
   8. BAD LOAN RATE BY LOAN PURPOSE
   ========================================================= */

SELECT
    purpose,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received
FROM dbo.financial_loan_database
GROUP BY purpose
ORDER BY bad_loan_rate DESC;



/* =========================================================
   9. BAD LOAN RATE BY DTI BAND
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN dti < 0.10 THEN 'Low DTI'
            WHEN dti < 0.20 THEN 'Medium DTI'
            ELSE 'High DTI'
        END AS dti_band
    FROM dbo.financial_loan_database
)

SELECT
    dti_band,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    AVG(dti) * 100 AS avg_dti,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY dti_band
ORDER BY bad_loan_rate DESC;



/* =========================================================
   10. BAD LOAN RATE BY INTEREST RATE BAND
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN int_rate < 0.10 THEN 'Low Interest'
            WHEN int_rate < 0.15 THEN 'Medium Interest'
            ELSE 'High Interest'
        END AS interest_rate_band
    FROM dbo.financial_loan_database
)

SELECT
    interest_rate_band,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    AVG(int_rate) * 100 AS avg_interest_rate,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY interest_rate_band
ORDER BY bad_loan_rate DESC;



/* =========================================================
   11. BAD LOAN RATE BY LOAN AMOUNT BAND
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN loan_amount < 5000 THEN 'Small Loan'
            WHEN loan_amount < 15000 THEN 'Medium Loan'
            ELSE 'Large Loan'
        END AS loan_amount_band
    FROM dbo.financial_loan_database
)

SELECT
    loan_amount_band,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    AVG(loan_amount) AS avg_loan_amount,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY loan_amount_band
ORDER BY bad_loan_rate DESC;



/* =========================================================
   12. BAD LOAN RATE BY INCOME BAND
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN annual_income < 40000 THEN 'Low Income'
            WHEN annual_income < 80000 THEN 'Medium Income'
            ELSE 'High Income'
        END AS income_band
    FROM dbo.financial_loan_database
)

SELECT
    income_band,
    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    AVG(annual_income) AS avg_annual_income,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY income_band
ORDER BY bad_loan_rate DESC;



/* =========================================================
   13. MONTHLY PORTFOLIO TREND
   ========================================================= */

SELECT
    MONTH(issue_date) AS issue_month_number,
    DATENAME(MONTH, issue_date) AS issue_month,

    COUNT(id) AS total_loan_applications,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,

    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti
FROM dbo.financial_loan_database
GROUP BY
    MONTH(issue_date),
    DATENAME(MONTH, issue_date)
ORDER BY issue_month_number;



/* =========================================================
   14. MONTHLY RISK DRIFT WITH WINDOW FUNCTION
   ========================================================= */

WITH monthly_risk AS (
    SELECT
        MONTH(issue_date) AS issue_month_number,
        DATENAME(MONTH, issue_date) AS issue_month,

        COUNT(id) AS total_loans,

        SUM(CASE 
            WHEN loan_status = 'Charged Off' 
            THEN 1 ELSE 0 
        END) AS bad_loans,

        SUM(CASE 
            WHEN loan_status = 'Charged Off' 
            THEN 1 ELSE 0 
        END) * 100.0 / COUNT(id) AS bad_loan_rate,

        SUM(loan_amount) AS total_funded_amount,
        SUM(total_payment) AS total_amount_received,
        AVG(int_rate) * 100 AS avg_interest_rate,
        AVG(dti) * 100 AS avg_dti
    FROM dbo.financial_loan_database
    GROUP BY
        MONTH(issue_date),
        DATENAME(MONTH, issue_date)
)

SELECT
    issue_month_number,
    issue_month,

    total_loans,
    bad_loans,
    bad_loan_rate,

    bad_loan_rate 
        - LAG(bad_loan_rate) OVER (ORDER BY issue_month_number) 
        AS mom_bad_loan_rate_change,

    total_funded_amount,

    total_funded_amount 
        - LAG(total_funded_amount) OVER (ORDER BY issue_month_number) 
        AS mom_funded_amount_change,

    total_amount_received,

    avg_interest_rate,

    avg_interest_rate 
        - LAG(avg_interest_rate) OVER (ORDER BY issue_month_number) 
        AS mom_avg_interest_rate_change,

    avg_dti,

    avg_dti 
        - LAG(avg_dti) OVER (ORDER BY issue_month_number) 
        AS mom_avg_dti_change
FROM monthly_risk
ORDER BY issue_month_number;



/* =========================================================
   15. GRADE × TERM RISK MATRIX
   ========================================================= */

SELECT
    grade,
    term,

    COUNT(id) AS total_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) AS bad_loans,

    SUM(CASE 
        WHEN loan_status = 'Charged Off' 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(id) AS bad_loan_rate,

    SUM(loan_amount) AS total_funded_amount
FROM dbo.financial_loan_database
GROUP BY grade, term
ORDER BY grade, term;



/* =========================================================
   16. HIGH-RISK SEGMENT ANALYSIS
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN dti < 0.10 THEN 'Low DTI'
            WHEN dti < 0.20 THEN 'Medium DTI'
            ELSE 'High DTI'
        END AS dti_band,

        CASE
            WHEN int_rate < 0.10 THEN 'Low Interest'
            WHEN int_rate < 0.15 THEN 'Medium Interest'
            ELSE 'High Interest'
        END AS interest_rate_band
    FROM dbo.financial_loan_database
),

segment_summary AS (
    SELECT
        grade,
        term,
        dti_band,
        interest_rate_band,
        purpose,

        COUNT(id) AS total_loans,

        SUM(CASE 
            WHEN loan_status = 'Charged Off' 
            THEN 1 ELSE 0 
        END) AS bad_loans,

        SUM(CASE 
            WHEN loan_status = 'Charged Off' 
            THEN 1 ELSE 0 
        END) * 100.0 / COUNT(id) AS bad_loan_rate,

        SUM(loan_amount) AS total_funded_amount
    FROM loan_features
    GROUP BY
        grade,
        term,
        dti_band,
        interest_rate_band,
        purpose
)

SELECT TOP 20
    grade,
    term,
    dti_band,
    interest_rate_band,
    purpose,

    total_loans,
    bad_loans,
    bad_loan_rate,
    total_funded_amount
FROM segment_summary
WHERE total_loans >= 30
ORDER BY bad_loan_rate DESC;



/* =========================================================
   17. RECOMMENDATION SUPPORT TABLE
   ========================================================= */

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN dti < 0.10 THEN 'Low DTI'
            WHEN dti < 0.20 THEN 'Medium DTI'
            ELSE 'High DTI'
        END AS dti_band,

        CASE
            WHEN int_rate < 0.10 THEN 'Low Interest'
            WHEN int_rate < 0.15 THEN 'Medium Interest'
            ELSE 'High Interest'
        END AS interest_rate_band,

        CASE
            WHEN loan_status = 'Charged Off' THEN 1
            ELSE 0
        END AS bad_loan_flag
    FROM dbo.financial_loan_database
)

SELECT
    'Long-term loans' AS risk_theme,
    term AS segment,
    COUNT(id) AS total_loans,
    SUM(bad_loan_flag) AS bad_loans,
    SUM(bad_loan_flag) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY term

UNION ALL

SELECT
    'Credit grade' AS risk_theme,
    grade AS segment,
    COUNT(id) AS total_loans,
    SUM(bad_loan_flag) AS bad_loans,
    SUM(bad_loan_flag) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY grade

UNION ALL

SELECT
    'DTI band' AS risk_theme,
    dti_band AS segment,
    COUNT(id) AS total_loans,
    SUM(bad_loan_flag) AS bad_loans,
    SUM(bad_loan_flag) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY dti_band

UNION ALL

SELECT
    'Interest rate band' AS risk_theme,
    interest_rate_band AS segment,
    COUNT(id) AS total_loans,
    SUM(bad_loan_flag) AS bad_loans,
    SUM(bad_loan_flag) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount
FROM loan_features
GROUP BY interest_rate_band
ORDER BY risk_theme, bad_loan_rate DESC;



/*
Validation Notes:
- Total loan applications should match COUNT(id)
- Good loan count = Fully Paid + Current
- Bad loan count = Charged Off
- Bad loan rate = Bad loan count / Total loan applications
- Recovery ratio = Total amount received / Total funded amount

Limitation:
This dataset does not contain repayment schedule, DPD history, or monthly loan snapshots.
Therefore, true DPD and vintage curve analysis cannot be calculated directly.
Loan status, bad loan rate, recovery ratio, and issue-month trend are used as proxy indicators
for portfolio risk monitoring.
*/