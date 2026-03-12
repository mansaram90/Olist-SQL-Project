--Find how much total money was paid using each payment type, and rank them from highest to lowest.
SELECT
    op.payment_type,
    SUM(op.payment_value) AS total_paid,
    COUNT(*) AS payment_rows
FROM dbo.order_payments op
GROUP BY op.payment_type
ORDER BY total_paid DESC;