--Find the top 10 sellers by number of delivered orders.
SELECT TOP 10
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS delivered_order_count
FROM dbo.orders o
JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY delivered_order_count DESC;