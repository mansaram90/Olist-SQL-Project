--Find the average review score for each product category and show the top 10 highest-rated categories.
SELECT TOP 10
    COALESCE(pcnt.product_category_name_english, p.product_category_name) AS category_name,
    AVG(CAST(r.review_score AS FLOAT)) AS avg_review_score,
    COUNT(*) AS review_count
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pcnt
    ON p.product_category_name = pcnt.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(pcnt.product_category_name_english, p.product_category_name)
ORDER BY avg_review_score DESC, review_count DESC;