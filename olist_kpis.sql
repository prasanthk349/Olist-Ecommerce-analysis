-- Olist E-Commerce Analysis: KPI queries
-- Database: MySQL | Results validated against the Power BI dashboard
-- Note: date columns were imported as text (DD-MM-YYYY HH:MM), so STR_TO_DATE is used

-- 1. Total sales, orders and customers
-- Result: 13,591,643.7 sales | 99,441 orders | 96,096 customers
SELECT
  ROUND(SUM(oi.price), 2) AS total_sales,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id;

-- 2. Late delivery % (delivered after the estimated date)
-- Result: 7.87
SELECT ROUND(100 * SUM(
  STR_TO_DATE(order_delivered_customer_date, '%d-%m-%Y %H:%i') >
  STR_TO_DATE(order_estimated_delivery_date, '%d-%m-%Y %H:%i')
) / COUNT(*), 2) AS late_delivery_pct
FROM olist_orders_dataset;
 Repeated customer % (customers with more than one order)
-- Result: 3.12
SELECT ROUND(100 * SUM(order_count > 1) / COUNT(*), 2) AS repeat_customer_pct
FROM (
  SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
  FROM olist_orders_dataset o
  JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
  GROUP BY c.customer_unique_id
) t;

-- 4. Monthly sales trend
-- Check: Nov 2017 should be the peak, around 1.0M
SELECT
  DATE_FORMAT(STR_TO_DATE(o.order_purchase_timestamp, '%d-%m-%Y %H:%i'), '%Y-%m') AS order_month,
  ROUND(SUM(oi.price), 2) AS monthly_sales
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

-- 5. Top 5 product categories by sales
-- Check: beleza_saude 1.26M, relogios_presentes 1.21M, cama_mesa_banho 1.04M
SELECT
  p.product_category_name,
  ROUND(SUM(oi.price), 2) AS category_sales
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY category_sales DESC
LIMIT 5;

-- 6. Average review score: on-time vs late deliveries
-- Check: on time about 4.3, late about 2.6
SELECT
  CASE
    WHEN STR_TO_DATE(o.order_delivered_customer_date, '%d-%m-%Y %H:%i') >
         STR_TO_DATE(o.order_estimated_delivery_date, '%d-%m-%Y %H:%i')
    THEN 'late' ELSE 'on time'
  END AS delivery_status,
  ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date <> ''
GROUP BY delivery_status;

