-- Top users by revenue
SELECT
    user_id,
    SUM(revenue) AS total_revenue
FROM orders
GROUP BY user_id
ORDER BY total_revenue DESC;


-- Returning users
SELECT
    user_id,
    COUNT(*) AS orders_count
FROM orders
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Revenue by month
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(revenue) AS revenue
FROM orders
GROUP BY month
ORDER BY month;
