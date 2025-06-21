-- 1. Extract the year, month, and day from the order placement date
SELECT order_placement_date,
       DATEPART(YEAR, order_placement_date) AS year,
       DATEPART(MONTH, order_placement_date) AS month,
       DATEPART(DAY, order_placement_date) AS day
FROM fact_orders_aggregate;

-- 2. View dimension and fact tables
SELECT * FROM dim_customers;
SELECT * FROM dim_products;
SELECT * FROM dim_targets_orders;
SELECT * FROM fact_orders_aggregate;
SELECT * FROM dim_date;
SELECT * FROM fact_order_lines;

-- 3. Total number of orders placed each month
SELECT COUNT(*), COUNT(DISTINCT order_id) FROM fact_order_lines;

WITH cte AS (
    SELECT order_id, COUNT(*) AS cnt
    FROM fact_order_lines
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
SELECT *
FROM fact_order_lines
LEFT JOIN cte ON fact_order_lines.order_id = cte.order_id;

-- 4. Monthly orders trend
SELECT COUNT(*), DATENAME(MONTH, order_placement_date)
FROM fact_order_lines
GROUP BY DATENAME(MONTH, order_placement_date);

-- 5. Days between order placement and actual delivery
SELECT order_placement_date, actual_delivery_date,
       DATEDIFF(DAY, order_placement_date, actual_delivery_date) AS days_diff
FROM fact_order_lines;

-- 6. Orders placed in the last 30 days
SELECT *
FROM fact_order_lines
WHERE order_placement_date > (
    SELECT DATEADD(DAY, -30, MAX(order_placement_date))
    FROM fact_order_lines
);

-- 7. Orders placed on a Monday
SELECT *
FROM fact_order_lines
WHERE DATENAME(WEEKDAY, order_placement_date) = 'Monday';

-- 8. Weekend vs weekday orders
SELECT COUNT(CASE WHEN DATENAME(WEEKDAY, order_placement_date) IN ('Saturday', 'Sunday') THEN 1 END) AS weekend,
       COUNT(CASE WHEN DATENAME(WEEKDAY, order_placement_date) NOT IN ('Saturday', 'Sunday') THEN 1 END) AS weekday
FROM fact_order_lines;

-- 9. Orders placed per week
SELECT COUNT(order_qty) AS cnt,
       DATEPART(WEEK, order_placement_date) AS week
FROM fact_order_lines
GROUP BY DATEPART(WEEK, order_placement_date)
ORDER BY week;

-- 10. Week with the highest number of orders
WITH cte AS (
    SELECT COUNT(order_qty) AS cnt,
           DATEPART(WEEK, order_placement_date) AS week
    FROM fact_order_lines
    GROUP BY DATEPART(WEEK, order_placement_date)
)
SELECT TOP 1 week, MAX(cnt) AS cnt
FROM cte
GROUP BY week;

-- 11. Earliest and latest order dates
SELECT MIN(order_placement_date) AS earliest_order,
       MAX(order_placement_date) AS latest_order
FROM fact_order_lines;

-- 12. Orders delivered in the same week they were placed
SELECT order_placement_date, actual_delivery_date, order_qty
FROM fact_order_lines
WHERE DATEPART(WEEK, order_placement_date) = DATEPART(WEEK, actual_delivery_date);

-- 13. Orders per month
SELECT COUNT(order_qty), DATENAME(MONTH, order_placement_date) AS month
FROM fact_order_lines
GROUP BY DATENAME(MONTH, order_placement_date);

-- 14. Weekly trend of late deliveries
WITH late_deliveries AS (
    SELECT *
    FROM fact_order_lines
    WHERE agreed_delivery_date < actual_delivery_date
)
SELECT DATEPART(WEEK, order_placement_date) AS week, COUNT(*) AS cnt
FROM late_deliveries
GROUP BY DATEPART(WEEK, order_placement_date)
ORDER BY week;

-- 15. Month with the highest number of orders not delivered in full
SELECT TOP 1 COUNT(order_qty) AS cnt,
       DATENAME(MONTH, order_placement_date) AS month
FROM fact_order_lines
WHERE on_time = 0
GROUP BY DATENAME(MONTH, order_placement_date)
ORDER BY cnt DESC;

-- 16. Difference between agreed and actual delivery dates
SELECT order_id, agreed_delivery_date, actual_delivery_date,
       DATEDIFF(DAY, agreed_delivery_date, actual_delivery_date) AS datediff
FROM fact_order_lines;

-- 17. OTIF performance per city
SELECT city, COUNT(order_qty) AS cnt
FROM fact_order_lines
LEFT JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
WHERE on_time_in_full = 1
GROUP BY city
ORDER BY cnt;

-- 18. Total number of late deliveries
SELECT COUNT(order_qty) AS cnt
FROM fact_order_lines
WHERE agreed_delivery_date < actual_delivery_date;

-- 19. Delivery timeliness breakdown
SELECT order_id, agreed_delivery_date, actual_delivery_date,
       CASE 
           WHEN agreed_delivery_date < actual_delivery_date THEN 'late'
           WHEN agreed_delivery_date = actual_delivery_date THEN 'same day'
           ELSE 'early'
       END AS status
FROM fact_order_lines;

-- 20. Product categories with number of unique products
SELECT category, COUNT(product_id) AS cnt
FROM dim_products
GROUP BY category;

-- 21. Busiest week by order placement
SELECT DATEPART(WEEK, order_placement_date) AS week,
       COUNT(order_qty) AS cnt
FROM fact_order_lines
GROUP BY DATEPART(WEEK, order_placement_date)
ORDER BY cnt DESC;

-- 22. Best performing product category for OTIF
SELECT TOP 1 category, COUNT(order_qty) AS cnt
FROM fact_order_lines
INNER JOIN dim_products ON fact_order_lines.product_id = dim_products.product_name
WHERE on_time_in_full = 1
GROUP BY category
ORDER BY cnt DESC;

-- 23. OTIF percentage
SELECT ROUND(CAST(COUNT(order_qty) AS NUMERIC) /
              (SELECT CAST(COUNT(*) AS NUMERIC) FROM fact_order_lines) * 100.0, 2)
FROM fact_order_lines
WHERE on_time_in_full = 1;

-- 24. Orders on weekends vs weekdays
SELECT SUM(CASE WHEN DATENAME(WEEKDAY, order_placement_date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END) AS weekend,
       SUM(CASE WHEN DATENAME(WEEKDAY, order_placement_date) NOT IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END) AS weekday
FROM fact_order_lines;

-- 25. On-time but not in-full
WITH orders AS (
    SELECT *
    FROM fact_order_lines
    WHERE on_time = 1
)
SELECT COUNT(*) AS cnt2
FROM orders
WHERE in_full = 0;

-- 26. Product category with highest order quantity
SELECT TOP 1 category, COUNT(order_qty)
FROM fact_order_lines
INNER JOIN dim_products ON fact_order_lines.product_id = dim_products.product_name
GROUP BY category
ORDER BY COUNT(order_qty) DESC;

-- 27. On-time delivery percentage by customer
WITH cte AS (
    SELECT customer_id, COUNT(*) AS overall,
           SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) AS on_time_orders
    FROM fact_order_lines
    GROUP BY customer_id
)
SELECT customer_id, overall, on_time_orders,
       (CAST(on_time_orders AS FLOAT) / overall) * 100.0 AS percentage
FROM cte;

-- 28. Successful delivery by customer (delivered_qty = order_qty)
WITH cte AS (
    SELECT customer_id, COUNT(order_id) AS overall_order,
           SUM(CASE WHEN delivery_qty = order_qty THEN 1 ELSE 0 END) AS main
    FROM fact_order_lines
    GROUP BY customer_id
),
cte2 AS (
    SELECT customer_id, overall_order, main,
           (CAST(main AS FLOAT) / overall_order) * 100.0 AS perc
    FROM cte
)
SELECT *
FROM dim_targets_orders
INNER JOIN cte2 ON dim_targets_orders.customer_id = cte2.customer_id;

-- 29. OTIF by product category
WITH cte AS (
    SELECT category, COUNT(*) AS overall,
           SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) AS main
    FROM fact_order_lines
    INNER JOIN dim_products ON fact_order_lines.product_id = dim_products.product_name
    GROUP BY category
)
SELECT category, overall, main, (CAST(main AS FLOAT) / overall) * 100.0 AS percentage
FROM cte;

-- 30. Customers who exceeded OTIF targets
WITH cte AS (
    SELECT customer_id, COUNT(order_id) AS overall_order,
           SUM(CASE WHEN delivery_qty = order_qty THEN 1 ELSE 0 END) AS main
    FROM fact_order_lines
    GROUP BY customer_id
),
cte2 AS (
    SELECT customer_id, overall_order, main,
           (CAST(main AS FLOAT) / overall_order) * 100.0 AS perc
    FROM cte
)
SELECT *
FROM dim_targets_orders
INNER JOIN cte2 ON dim_targets_orders.customer_id = cte2.customer_id;

-- 31. Customers with total product quantity greater than average
WITH cte AS (
    SELECT customer_id, SUM(order_qty) AS total
    FROM fact_order_lines
    GROUP BY customer_id
)
SELECT customer_id, SUM(order_qty) AS qty
FROM fact_order_lines
GROUP BY customer_id
HAVING SUM(order_qty) > (SELECT AVG(total) FROM cte);

-- 32. Customers below 80% OTIF target
WITH delivery_per AS (
    SELECT customer_id,
           SUM(CASE WHEN on_time_in_full = 1 THEN 1 ELSE 0 END) * 100 / COUNT(*) AS percentage
    FROM fact_order_lines
    GROUP BY customer_id
)
SELECT *, otif_target_percent * 0.80 AS target_80
FROM delivery_per
INNER JOIN dim_targets_orders ON delivery_per.customer_id = dim_targets_orders.customer_id
WHERE percentage < otif_target_percent * 0.80;

-- 33. Customers below 80% on-time AND in-full
WITH cte AS (
    SELECT customer_id,
           SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 100 / COUNT(*) AS on_time,
           SUM(CASE WHEN in_full = 1 THEN 1 ELSE 0 END) * 100 / COUNT(*) AS in_full
    FROM fact_order_lines
    GROUP BY customer_id
)
SELECT customer_id, on_time, in_full
FROM cte
WHERE on_time < 80 AND in_full < 80;

-- 34. Monthly on-time and in-full performance vs targets
WITH cte AS (
    SELECT customer_id,
           DATENAME(MONTH, order_placement_date) AS maindate,
           DATEPART(MONTH, order_placement_date) AS mth,
           SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 100 / COUNT(*) AS ontime,
           SUM(CASE WHEN in_full = 1 THEN 1 ELSE 0 END) * 100 / COUNT(*) AS in_full
    FROM fact_order_lines
    GROUP BY customer_id, DATENAME(MONTH, order_placement_date), DATEPART(MONTH, order_placement_date)
)
SELECT cte.customer_id, maindate, mth, ontime, in_full,
       ontime_target_percent, infull_target_percent
FROM cte
INNER JOIN dim_targets_orders ON cte.customer_id = dim_targets_orders.customer_id
WHERE ontime < ontime_target_percent AND in_full < infull_target_percent
ORDER BY customer_id, mth;

-- 35. Categories with highest and lowest on-time rates
WITH highest_rate AS (
    SELECT TOP 1 productname, 'Highest on-time rate' AS category,
           ROUND(SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ontime_perc,
           ROUND(SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS ontime_rt,
           SUM(order_qty) AS totalorders
    FROM fact_order_lines
    INNER JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
    GROUP BY productname
    HAVING SUM(order_qty) > 200
    ORDER BY ontime_rt DESC
),
lowest_rate AS (
    SELECT TOP 1 productname, 'Lowest on-time rate' AS category,
           ROUND(SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ontime_perc,
           ROUND(SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS ontime_rt,
           SUM(order_qty) AS totalorders
    FROM fact_order_lines
    INNER JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
    GROUP BY productname
    HAVING SUM(order_qty) > 200
    ORDER BY ontime_rt ASC
)
SELECT * FROM highest_rate
UNION ALL
SELECT * FROM lowest_rate;
