--Question 2 — Seller leaderboard by month and state with revenue share
--Problem statement: For each month and seller_state, compute seller GMV (sum of order_items X price) and rank sellers within each state-month. 
--Return the top 5 sellers per state-month with their share of state-month GMV and cumulative share across the ranked sellers.

WITH delivered AS (
  SELECT order_id, order_purchase_timestamp
  FROM orders
  WHERE order_status = 'delivered'
),
seller_month AS (
  SELECT
    DATEFROMPARTS(YEAR(d.order_purchase_timestamp), MONTH(d.order_purchase_timestamp), 1) AS month_start,
    s.seller_state,
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS orders_cnt,
    SUM(oi.price) AS gmv
  FROM delivered d
  JOIN order_items oi ON oi.order_id = d.order_id
  JOIN sellers s ON s.seller_id = oi.seller_id
  GROUP BY
    DATEFROMPARTS(YEAR(d.order_purchase_timestamp), MONTH(d.order_purchase_timestamp), 1),
    s.seller_state,
    oi.seller_id
),
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY month_start, seller_state ORDER BY gmv DESC) AS seller_rank,
    SUM(gmv) OVER (PARTITION BY month_start, seller_state) AS state_gmv,
    SUM(gmv) OVER (
      PARTITION BY month_start, seller_state
      ORDER BY gmv DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_gmv
  FROM seller_month
)
SELECT
  month_start,
  seller_state,
  seller_id,
  gmv,
  orders_cnt,
  seller_rank,
  gmv / NULLIF(state_gmv, 0) AS share_of_state_gmv,
  cumulative_gmv / NULLIF(state_gmv, 0) AS cumulative_share
FROM ranked
WHERE seller_rank <= 5
ORDER BY month_start, seller_state, seller_rank, seller_id;
