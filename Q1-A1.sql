--Question 1: Order value reconciliation and discrepancy leaderboard
--Problem statement: Build an order-level reconciliation report comparing (a) sum of item prices + freight from order_items versus (b) sum of payments from order_payments. 
--Return the top 50 delivered orders with the largest absolute discrepancy, including whether the order has multiple payment rows.

WITH delivered_orders AS (
  SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.customer_id
  FROM dbo.orders o
  WHERE o.order_status = 'delivered'
),
items_agg AS (
  SELECT
    oi.order_id,
    SUM(oi.price) AS items_total,
    SUM(oi.freight_value) AS freight_total
  FROM dbo.order_items oi
  GROUP BY oi.order_id
),
payments_agg AS (
  SELECT
    op.order_id,
    SUM(op.payment_value) AS paid_total,
    COUNT(*) AS payment_rows,
    COUNT(DISTINCT op.payment_type) AS payment_types_count
  FROM dbo.order_payments op
  GROUP BY op.order_id
),
recon AS (
  SELECT
    d.order_id,
    d.order_purchase_timestamp,
    c.customer_state,
    COALESCE(i.items_total, 0) AS items_total,
    COALESCE(i.freight_total, 0) AS freight_total,
    COALESCE(p.paid_total, 0) AS paid_total,
    COALESCE(p.paid_total, 0) - (COALESCE(i.items_total, 0) + COALESCE(i.freight_total, 0)) AS discrepancy,
    COALESCE(p.payment_rows, 0) AS payment_rows,
    COALESCE(p.payment_types_count, 0) AS payment_types_count
  FROM delivered_orders d
  JOIN dbo.customers c ON c.customer_id = d.customer_id
  LEFT JOIN items_agg i ON i.order_id = d.order_id
  LEFT JOIN payments_agg p ON p.order_id = d.order_id
)
SELECT TOP (50)
  *
FROM recon
ORDER BY ABS(discrepancy) DESC, order_purchase_timestamp DESC;