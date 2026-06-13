/*
Credit Risk Portfolio Analytics
Skills used: Aggregate Functions, CASE WHEN, CTEs, Window Functions, Risk Segmentation

Business Objective:
Analyze loan portfolio performance, identify high-risk borrower segments,
and monitor monthly credit risk drift.

Key Assumptions:
- Good Loan = Fully Paid or Current
- Bad Loan = Charged Off
- issue_date = loan origination date
- Dataset does not include DPD or repayment schedule, so bad loan rate is used as a proxy risk metric
*/


-- 1. View Raw Data

SELECT *
FROM bank_loan_data;



-- 2. Data Quality Check

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT id) AS unique_loan_ids,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS missing_id,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) AS missing_loan_amount,
    SUM(CASE WHEN total_payment IS NULL THEN 1 ELSE 0 END) AS missing_total_payment,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS missing_loan_status,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) AS missing_issue_date
FROM bank_loan_data;



-- 3. Portfolio KPI Summary

SELECT
    COUNT(id) AS total_loan_applications,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,
    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti,

    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) AS good_loan_count,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loan_count,

    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS good_loan_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,

    SUM(total_payment) * 1.0 / NULLIF(SUM(loan_amount), 0) AS recovery_ratio
FROM bank_loan_data;



-- 4. Good Loan vs Bad Loan Summary

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
FROM bank_loan_data
GROUP BY
    CASE
        WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
        WHEN loan_status = 'Charged Off' THEN 'Bad Loan'
        ELSE 'Other'
    END;



-- 5. Create Risk Features with CTE

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

        total_payment * 1.0 / NULLIF(loan_amount, 0) AS recovery_ratio
    FROM bank_loan_data
)

SELECT *
FROM loan_features;



-- 6. Bad Loan Rate by Credit Grade

SELECT
    grade,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti,
    SUM(loan_amount) AS total_funded_amount
FROM bank_loan_data
GROUP BY grade
ORDER BY grade;



-- 7. Bad Loan Rate by Term

SELECT
    term,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount,
    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti
FROM bank_loan_data
GROUP BY term
ORDER BY term;



-- 8. Bad Loan Rate by Loan Purpose

SELECT
    purpose,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
    SUM(loan_amount) AS total_funded_amount
FROM bank_loan_data
GROUP BY purpose
ORDER BY bad_loan_rate DESC;



-- 9. Bad Loan Rate by DTI Band

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN dti < 0.10 THEN 'Low DTI'
            WHEN dti < 0.20 THEN 'Medium DTI'
            ELSE 'High DTI'
        END AS dti_band
    FROM bank_loan_data
)

SELECT
    dti_band,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
    AVG(dti) * 100 AS avg_dti
FROM loan_features
GROUP BY dti_band
ORDER BY bad_loan_rate DESC;



-- 10. Bad Loan Rate by Interest Rate Band

WITH loan_features AS (
    SELECT
        *,
        CASE
            WHEN int_rate < 0.10 THEN 'Low Interest'
            WHEN int_rate < 0.15 THEN 'Medium Interest'
            ELSE 'High Interest'
        END AS interest_rate_band
    FROM bank_loan_data
)

SELECT
    interest_rate_band,
    COUNT(id) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
    AVG(int_rate) * 100 AS avg_interest_rate
FROM loan_features
GROUP BY interest_rate_band
ORDER BY bad_loan_rate DESC;



-- 11. Monthly Portfolio Trend

SELECT
    MONTH(issue_date) AS issue_month_number,
    DATENAME(MONTH, issue_date) AS issue_month,
    COUNT(id) AS total_loan_applications,
    SUM(loan_amount) AS total_funded_amount,
    SUM(total_payment) AS total_amount_received,
    AVG(int_rate) * 100 AS avg_interest_rate,
    AVG(dti) * 100 AS avg_dti
FROM bank_loan_data
GROUP BY
    MONTH(issue_date),
    DATENAME(MONTH, issue_date)
ORDER BY issue_month_number;



-- 12. Monthly Risk Drift with Window Function

WITH monthly_risk AS (
    SELECT
        MONTH(issue_date) AS issue_month_number,
        DATENAME(MONTH, issue_date) AS issue_month,
        COUNT(id) AS total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
        SUM(loan_amount) AS total_funded_amount
    FROM bank_loan_data
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
    bad_loan_rate - LAG(bad_loan_rate) OVER (ORDER BY issue_month_number) AS mom_bad_loan_rate_change,
    total_funded_amount,
    total_funded_amount - LAG(total_funded_amount) OVER (ORDER BY issue_month_number) AS mom_funded_amount_change
FROM monthly_risk
ORDER BY issue_month_number;



-- 13. High-Risk Segment Analysis

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
    FROM bank_loan_data
),

segment_summary AS (
    SELECT
        grade,
        term,
        dti_band,
        interest_rate_band,
        purpose,
        COUNT(id) AS total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS bad_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id) AS bad_loan_rate,
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
Loan status, bad loan rate, recovery ratio, and issue-month trend are used as proxy indicators.
*/
