--Compute RFM metrics per customer_unique_id for delivered orders:
-- Recency = days since last delivered purchase (relative to dataset max delivered purchase date)
-- Frequency = number of delivered orders
-- Monetary = sum of payment_value across delivered orders
--Assign each metric into quartiles using NTILE(4) and produce an rfm_segment_code such as R4F3M4.
WITH delivered_orders AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp
  FROM orders o
  WHERE o.order_status = 'delivered'
),
payments_per_order AS (
  SELECT
    op.order_id,
    SUM(op.payment_value) AS order_paid
  FROM order_payments op
  GROUP BY op.order_id
),
base AS (
  SELECT
    c.customer_unique_id,
    d.order_id,
    d.order_purchase_timestamp,
    COALESCE(p.order_paid, 0) AS order_paid
  FROM delivered_orders d
  JOIN customers c ON c.customer_id = d.customer_id
  LEFT JOIN payments_per_order p ON p.order_id = d.order_id
),
params AS (
  SELECT MAX(order_purchase_timestamp) AS max_ts
  FROM base
),
rfm AS (
  SELECT
    b.customer_unique_id,
    DATEDIFF(DAY, MAX(b.order_purchase_timestamp), (SELECT max_ts FROM params)) AS recency_days,
    COUNT(DISTINCT b.order_id) AS frequency_orders,
    SUM(b.order_paid) AS monetary_value
  FROM base b
  GROUP BY b.customer_unique_id
),
scored AS (
  SELECT
    *,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS r_quartile,
    NTILE(4) OVER (ORDER BY frequency_orders) AS f_quartile,
    NTILE(4) OVER (ORDER BY monetary_value) AS m_quartile
  FROM rfm
)
SELECT
  customer_unique_id,
  recency_days,
  frequency_orders,
  monetary_value,
  r_quartile,
  f_quartile,
  m_quartile,
  CONCAT('R', r_quartile, 'F', f_quartile, 'M', m_quartile) AS rfm_segment_code
FROM scored
ORDER BY monetary_value DESC;