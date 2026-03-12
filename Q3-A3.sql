--Question 3: Monthly cohort retention (long format)
--Problem statement: Create monthly cohorts by each customer’s first delivered order month (using customer_unique_id). 
--For each cohort, compute retention for months 0–12 as: active customers in month N / cohort size. 
--Output in long format: one row per (cohort_month, months_since, active_customers, cohort_size, retention_rate).
WITH delivered_orders AS (
  SELECT
    o.order_id,
    o.customer_id,
    DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1) AS order_month
  FROM dbo.orders o
  WHERE o.order_status = 'delivered'
),
cust AS (
  SELECT customer_id, customer_unique_id
  FROM dbo.customers
),
cust_orders AS (
  SELECT
    c.customer_unique_id,
    d.order_id,
    d.order_month
  FROM delivered_orders d
  JOIN cust c ON c.customer_id = d.customer_id
),
cohort AS (
  SELECT
    customer_unique_id,
    MIN(order_month) AS cohort_month
  FROM cust_orders
  GROUP BY customer_unique_id
),
activity AS (
  SELECT
    co.cohort_month,
    DATEDIFF(MONTH, co.cohort_month, o.order_month) AS months_since,
    o.customer_unique_id
  FROM cust_orders o
  JOIN cohort co ON co.customer_unique_id = o.customer_unique_id
)
SELECT
  cohort_month,
  months_since,
  COUNT(DISTINCT customer_unique_id) AS active_customers,
  MAX(CASE WHEN months_since = 0 THEN COUNT(DISTINCT customer_unique_id) END)
    OVER (PARTITION BY cohort_month) AS cohort_size,
  1.0 * COUNT(DISTINCT customer_unique_id)
    / NULLIF(
        MAX(CASE WHEN months_since = 0 THEN COUNT(DISTINCT customer_unique_id) END)
          OVER (PARTITION BY cohort_month),
        0
      ) AS retention_rate
FROM activity
WHERE months_since BETWEEN 0 AND 12
GROUP BY cohort_month, months_since
ORDER BY cohort_month, months_since;