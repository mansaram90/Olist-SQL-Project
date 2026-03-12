--For each (customer_state, product_category_english), compute:
-- number of delivered orders represented
-- median and 90th percentile of delivery delay in days = delivered_customer_date − estimated_delivery_date
--Return the worst 20 state-category pairs by median delay (ties broken by p90).

WITH base AS (
  SELECT DISTINCT
    c.customer_state,
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category_english,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delay_days
  FROM dbo.orders o
  JOIN dbo.customers c ON c.customer_id = o.customer_id
  JOIN dbo.order_items oi ON oi.order_id = o.order_id
  JOIN dbo.products p ON p.product_id = oi.product_id
  LEFT JOIN dbo.product_category_name_translation ct ON ct.product_category_name = p.product_category_name
  WHERE o.order_status = 'delivered'
    AND o.order_estimated_delivery_date IS NOT NULL
    AND o.order_delivered_customer_date IS NOT NULL
),
stats AS (
  SELECT
    customer_state,
    category_english,
    COUNT(*) OVER (PARTITION BY customer_state, category_english) AS orders_cnt,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delay_days)
      OVER (PARTITION BY customer_state, category_english) AS median_delay_days,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY delay_days)
      OVER (PARTITION BY customer_state, category_english) AS p90_delay_days,
    ROW_NUMBER() OVER (PARTITION BY customer_state, category_english ORDER BY customer_state) AS rn
  FROM base
)
SELECT TOP (20)
  customer_state,
  category_english,
  orders_cnt,
  median_delay_days,
  p90_delay_days
FROM stats
WHERE rn = 1
ORDER BY median_delay_days DESC, p90_delay_days DESC, orders_cnt DESC;