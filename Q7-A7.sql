--Find customers who made purchases in more than one different month.

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT CONCAT(YEAR(o.order_purchase_timestamp), '-', MONTH(o.order_purchase_timestamp))) AS active_months
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT CONCAT(YEAR(o.order_purchase_timestamp), '-', MONTH(o.order_purchase_timestamp))) > 1
ORDER BY active_months DESC;