-- ============================================================
--  OLIST E-COMMERCE — SENIOR DATA ANALYST SQL ASSIGNMENT
--  Database  : PostgreSQL
--  Dataset   : Brazilian E-Commerce Public Dataset (Olist)
--  Revenue   : SUM(price) — excludes freight unless noted
--  Date ref  : order_purchase_timestamp for all temporal work
--  Delivery  : Only order_status = 'delivered' for revenue tasks
-- ============================================================


-- ============================================================
-- TASK 1 — REVENUE & CATEGORY INTELLIGENCE
-- ============================================================

-- ------------------------------------------------------------
-- TASK 1.1 — Total revenue and order count per category
-- ------------------------------------------------------------
WITH delivered_items AS (
    -- Filter delivered orders early to shrink downstream joins
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price,
        o.order_purchase_timestamp
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

category_revenue AS (
    SELECT
        t.product_category_name_english         AS category,
        ROUND(SUM(di.price)::NUMERIC, 2)        AS total_revenue,
        COUNT(DISTINCT di.order_id)             AS total_orders
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    GROUP BY t.product_category_name_english
)

SELECT
    category,
    total_revenue,
    total_orders
FROM category_revenue
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- TASK 1.2 — Month-over-Month revenue growth for top 5 categories
--            over the last 12 months
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

top5_categories AS (
    -- Rank all categories by total all-time revenue, keep top 5
    SELECT
        t.product_category_name_english AS category
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    GROUP BY t.product_category_name_english
    ORDER BY SUM(di.price) DESC
    LIMIT 5
),

monthly_revenue AS (
    -- Monthly revenue for those top 5 categories, last 12 months
    SELECT
        t.product_category_name_english         AS category,
        DATE_TRUNC('month', di.order_month)     AS month,
        ROUND(SUM(di.price)::NUMERIC, 2)        AS revenue
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english IN (SELECT category FROM top5_categories)
      AND di.order_month >= (
            -- Dynamically anchor to the most recent month in the data
            SELECT DATE_TRUNC('month', MAX(order_purchase_timestamp)) - INTERVAL '11 months'
            FROM orders
          )
    GROUP BY t.product_category_name_english, DATE_TRUNC('month', di.order_month)
),

mom_growth AS (
    SELECT
        category,
        month,
        revenue,
        -- LAG looks back 1 row within same category ordered by month
        LAG(revenue) OVER (
            PARTITION BY category
            ORDER BY month
        ) AS prev_month_revenue,
        -- MoM growth %: (current - previous) / previous * 100
        -- NULLIF prevents division by zero on the first month
        ROUND(
            (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY month))
            / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY month), 0)
            * 100
        , 2) AS mom_growth_pct
    FROM monthly_revenue
)

SELECT
    category,
    TO_CHAR(month, 'YYYY-MM') AS month,
    revenue,
    prev_month_revenue,
    mom_growth_pct
FROM mom_growth
ORDER BY category, month;


-- ------------------------------------------------------------
-- TASK 1.3 — Top 3 products by revenue within each top 5 category
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

top5_categories AS (
    SELECT
        t.product_category_name_english AS category
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    GROUP BY t.product_category_name_english
    ORDER BY SUM(di.price) DESC
    LIMIT 5
),

product_revenue AS (
    SELECT
        t.product_category_name_english         AS category,
        di.product_id,
        ROUND(SUM(di.price)::NUMERIC, 2)        AS product_revenue
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english IN (SELECT category FROM top5_categories)
    GROUP BY t.product_category_name_english, di.product_id
),

ranked_products AS (
    SELECT
        category,
        product_id,
        product_revenue,
        -- DENSE_RANK ensures ties don't skip ranks
        -- PARTITION BY restarts ranking per category
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC
        ) AS revenue_rank
    FROM product_revenue
)

SELECT
    category,
    product_id,
    product_revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;


-- ------------------------------------------------------------
-- TASK 1.4 — Avg review score & % low reviews for top products
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

top5_categories AS (
    SELECT t.product_category_name_english AS category
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    GROUP BY t.product_category_name_english
    ORDER BY SUM(di.price) DESC
    LIMIT 5
),

product_revenue AS (
    SELECT
        t.product_category_name_english         AS category,
        di.product_id,
        ROUND(SUM(di.price)::NUMERIC, 2)        AS product_revenue
    FROM delivered_items di
    JOIN products p             ON di.product_id = p.product_id
    JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english IN (SELECT category FROM top5_categories)
    GROUP BY t.product_category_name_english, di.product_id
),

ranked_products AS (
    SELECT
        category,
        product_id,
        product_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC
        ) AS revenue_rank
    FROM product_revenue
),

top3_products AS (
    SELECT category, product_id, product_revenue, revenue_rank
    FROM ranked_products
    WHERE revenue_rank <= 3
),

review_stats AS (
    -- Reviews are at order level in Olist — join via order_items → reviews
    -- Note: multi-item orders share one review across all their products
    SELECT
        oi.product_id,
        COUNT(DISTINCT r.review_id)                             AS total_reviews,
        ROUND(AVG(r.review_score)::NUMERIC, 2)                 AS avg_review_score,
        -- Conditional aggregation: CASE returns 1 or NULL; COUNT skips NULLs
        COUNT(CASE WHEN r.review_score <= 3 THEN 1 END)        AS low_score_count,
        ROUND(
            COUNT(CASE WHEN r.review_score <= 3 THEN 1 END)::NUMERIC
            / NULLIF(COUNT(r.review_id), 0)
            * 100
        , 2)                                                    AS pct_low_reviews
    FROM order_items oi
    JOIN reviews r ON oi.order_id = r.order_id
    WHERE oi.product_id IN (SELECT product_id FROM top3_products)
    GROUP BY oi.product_id
)

SELECT
    tp.category,
    tp.revenue_rank,
    tp.product_id,
    tp.product_revenue,
    rs.total_reviews,
    rs.avg_review_score,
    rs.low_score_count,
    rs.pct_low_reviews
FROM top3_products tp
LEFT JOIN review_stats rs ON tp.product_id = rs.product_id
ORDER BY tp.category, tp.revenue_rank;


-- ============================================================
-- TASK 2 — RFM CUSTOMER SEGMENTATION
-- Reference date: 2018-10-17
-- Recency  = days since last order (lower = better → score 5)
-- Frequency= total delivered orders (higher = better → score 5)
-- Monetary = total price sum (higher = better → score 5)
-- ============================================================
WITH rfm_base AS (
    -- One row per unique customer with R, F, M raw values
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE          AS last_order_date,
        -- Recency: days from last order to reference date
        (DATE '2018-10-17' - MAX(o.order_purchase_timestamp)::DATE) AS recency_days,
        COUNT(DISTINCT o.order_id)                     AS frequency,
        ROUND(SUM(oi.price)::NUMERIC, 2)               AS monetary
    FROM customers c
    JOIN orders o     ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id  = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        -- NTILE(5) splits into 5 equal buckets
        -- Recency: fewer days = more recent = higher score → ORDER DESC so small days → bucket 5
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS recency_score,
        -- Frequency & Monetary: higher = better → ORDER ASC so highest → bucket 5
        NTILE(5) OVER (ORDER BY frequency)          AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary)           AS monetary_score
    FROM rfm_base
),

rfm_labeled AS (
    SELECT
        rs.*,
        -- Concatenate scores into single RFM string e.g. '5-4-5'
        CONCAT(recency_score, '-', frequency_score, '-', monetary_score) AS rfm_score,
        -- Total score for ranking
        (recency_score + frequency_score + monetary_score)               AS total_rfm_score
    FROM rfm_scores rs
)

SELECT
    rl.customer_unique_id,
    rl.rfm_score,
    rl.total_rfm_score,
    rl.recency_days,
    rl.frequency,
    rl.monetary,
    rl.recency_score,
    rl.frequency_score,
    rl.monetary_score,
    -- Join back for city and state (use first customer_id for this unique customer)
    c.customer_city  AS city,
    c.customer_state AS state
FROM rfm_labeled rl
-- customer_unique_id can map to multiple customer_ids; pick one for location
JOIN customers c ON c.customer_unique_id = rl.customer_unique_id
-- De-duplicate in case of multiple customer_ids per unique customer
QUALIFY ROW_NUMBER() OVER (PARTITION BY rl.customer_unique_id ORDER BY c.customer_id) = 1
ORDER BY rl.total_rfm_score DESC, rl.recency_days ASC
LIMIT 10;


-- ============================================================
-- TASK 3 — SELLER PERFORMANCE & UNDERPERFORMERS
-- ============================================================

-- ------------------------------------------------------------
-- TASK 3.1 — Per seller: revenue, avg delivery days,
--            avg review score, total orders
-- ------------------------------------------------------------
WITH seller_stats AS (
    SELECT
        oi.seller_id,
        ROUND(SUM(oi.price)::NUMERIC, 2)                AS total_revenue,
        COUNT(DISTINCT o.order_id)                      AS total_orders,
        -- Delivery days: purchase → delivered_customer_date
        ROUND(AVG(
            EXTRACT(DAY FROM AGE(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            ))
        )::NUMERIC, 2)                                  AS avg_delivery_days,
        ROUND(AVG(r.review_score)::NUMERIC, 2)          AS avg_review_score
    FROM orders o
    JOIN order_items oi ON o.order_id  = oi.order_id
    JOIN reviews r      ON o.order_id  = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.seller_id
)

SELECT
    ss.seller_id,
    s.seller_city,
    s.seller_state,
    ss.total_revenue,
    ss.total_orders,
    ss.avg_delivery_days,
    ss.avg_review_score
FROM seller_stats ss
JOIN sellers s ON ss.seller_id = s.seller_id
ORDER BY ss.total_revenue DESC;


-- ------------------------------------------------------------
-- TASK 3.2 — Rank sellers within each state by revenue
-- ------------------------------------------------------------
WITH seller_stats AS (
    SELECT
        oi.seller_id,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)

SELECT
    s.seller_state,
    s.seller_id,
    ss.total_revenue,
    -- RANK() within each state; ties get same rank, next rank skips
    RANK() OVER (
        PARTITION BY s.seller_state
        ORDER BY ss.total_revenue DESC
    ) AS state_revenue_rank
FROM seller_stats ss
JOIN sellers s ON ss.seller_id = s.seller_id
ORDER BY s.seller_state, state_revenue_rank;


-- ------------------------------------------------------------
-- TASK 3.3 — Underperforming sellers
--            Criteria: avg_delivery_days > (overall_avg + 2 * stddev)
--                  AND avg_review_score  < overall_avg_review_score
-- ------------------------------------------------------------
WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        ROUND(AVG(
            EXTRACT(DAY FROM AGE(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            ))
        )::NUMERIC, 2)                          AS avg_delivery_days,
        ROUND(AVG(r.review_score)::NUMERIC, 2)  AS avg_review_score
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN reviews r      ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.seller_id
),

overall_benchmarks AS (
    -- Single-row benchmark: overall avg and stddev for delivery and review
    SELECT
        AVG(avg_delivery_days)                              AS overall_avg_delivery,
        STDDEV(avg_delivery_days)                           AS overall_stddev_delivery,
        AVG(avg_review_score)                               AS overall_avg_review
    FROM seller_metrics
)

SELECT
    sm.seller_id,
    s.seller_city,
    s.seller_state,
    sm.avg_delivery_days,
    sm.avg_review_score,
    ROUND(ob.overall_avg_delivery::NUMERIC, 2)  AS benchmark_delivery,
    ROUND(ob.overall_avg_review::NUMERIC, 2)    AS benchmark_review
FROM seller_metrics sm
-- Cross join: overall_benchmarks is a single row, safe to cross join
CROSS JOIN overall_benchmarks ob
JOIN sellers s ON sm.seller_id = s.seller_id
WHERE
    -- Condition 1: delivery time is an outlier (> mean + 2 stddev)
    sm.avg_delivery_days > (ob.overall_avg_delivery + 2 * ob.overall_stddev_delivery)
    -- Condition 2: review score below overall average
    AND sm.avg_review_score < ob.overall_avg_review
ORDER BY sm.avg_delivery_days DESC;


-- ============================================================
-- TASK 4 — GEOGRAPHICAL & SHIPPING ANALYSIS
-- ============================================================

-- ------------------------------------------------------------
-- TASK 4.1 — Per customer state: revenue, unique customers,
--            avg delivery time, % late deliveries
-- ------------------------------------------------------------
SELECT
    c.customer_state                                        AS state,
    ROUND(SUM(oi.price)::NUMERIC, 2)                       AS total_revenue,
    COUNT(DISTINCT c.customer_unique_id)                   AS unique_customers,
    ROUND(AVG(
        EXTRACT(DAY FROM AGE(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        ))
    )::NUMERIC, 2)                                         AS avg_delivery_days,
    -- % late: actual delivery > estimated delivery
    ROUND(
        COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                   THEN 1 END)::NUMERIC
        / NULLIF(COUNT(o.order_id), 0)
        * 100
    , 2)                                                   AS pct_late_deliveries
FROM orders o
JOIN order_items oi ON o.order_id  = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- TASK 4.2 — Top 5 cities by avg review score (min 50 orders)
-- ------------------------------------------------------------
SELECT
    c.customer_city                                 AS city,
    c.customer_state                                AS state,
    COUNT(DISTINCT o.order_id)                      AS total_orders,
    ROUND(AVG(r.review_score)::NUMERIC, 2)          AS avg_review_score
FROM orders o
JOIN reviews r   ON o.order_id   = r.order_id
JOIN customers c ON o.customer_id = c.customer_id
-- All orders considered for reviews (not just delivered)
GROUP BY c.customer_city, c.customer_state
-- Only cities with at least 50 orders
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY avg_review_score DESC
LIMIT 5;


-- ------------------------------------------------------------
-- TASK 4.3 — Same-state vs cross-state: avg delivery time
--            and avg freight value
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN s.seller_state = c.customer_state THEN 'Same state'
        ELSE 'Cross state'
    END                                                     AS shipping_type,
    COUNT(DISTINCT o.order_id)                             AS total_orders,
    ROUND(AVG(
        EXTRACT(DAY FROM AGE(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        ))
    )::NUMERIC, 2)                                         AS avg_delivery_days,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2)               AS avg_freight_value
FROM orders o
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN sellers s      ON oi.seller_id  = s.seller_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY shipping_type
ORDER BY shipping_type;


-- ============================================================
-- TASK 5 — PAYMENT BEHAVIOR & INSTALLMENTS IMPACT
-- ============================================================

-- ------------------------------------------------------------
-- TASK 5.1 — Most common payment type overall
-- ------------------------------------------------------------
SELECT
    payment_type,
    COUNT(*)                                        AS payment_count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_total
FROM payments
GROUP BY payment_type
ORDER BY payment_count DESC
LIMIT 1;


-- ------------------------------------------------------------
-- TASK 5.2 — Order value bins: avg installments & % credit card
-- ------------------------------------------------------------
WITH order_totals AS (
    -- Total payment value per order
    SELECT
        order_id,
        SUM(payment_value)  AS order_total,
        MAX(payment_type)   AS payment_type,   -- dominant type per order
        MAX(installments)   AS installments
    FROM payments
    GROUP BY order_id
),

binned AS (
    SELECT
        -- CASE bucketing into value ranges
        CASE
            WHEN order_total <  50  THEN '0-50'
            WHEN order_total <  100 THEN '50-100'
            WHEN order_total <  200 THEN '100-200'
            WHEN order_total <  500 THEN '200-500'
            ELSE '500+'
        END                                                 AS value_bin,
        installments,
        payment_type
    FROM order_totals
)

SELECT
    value_bin,
    COUNT(*)                                                AS total_orders,
    ROUND(AVG(installments)::NUMERIC, 2)                   AS avg_installments,
    -- Conditional aggregation: count credit card orders
    ROUND(
        COUNT(CASE WHEN payment_type = 'credit_card' THEN 1 END)::NUMERIC
        / NULLIF(COUNT(*), 0) * 100
    , 2)                                                    AS pct_credit_card
FROM binned
GROUP BY value_bin
-- Custom sort order for bins
ORDER BY CASE value_bin
    WHEN '0-50'    THEN 1
    WHEN '50-100'  THEN 2
    WHEN '100-200' THEN 3
    WHEN '200-500' THEN 4
    WHEN '500+'    THEN 5
END;


-- ------------------------------------------------------------
-- TASK 5.3 — Credit card orders grouped by installment bands:
--            avg review score & % low reviews
-- ------------------------------------------------------------
WITH credit_orders AS (
    -- Only credit card payments, aggregate to order level
    SELECT
        order_id,
        MAX(installments) AS installments
    FROM payments
    WHERE payment_type = 'credit_card'
    GROUP BY order_id
),

installment_bands AS (
    SELECT
        co.order_id,
        -- Group installments into bands
        CASE
            WHEN co.installments = 1        THEN '1'
            WHEN co.installments BETWEEN 2 AND 3 THEN '2-3'
            WHEN co.installments BETWEEN 4 AND 6 THEN '4-6'
            ELSE '7+'
        END AS installment_band
    FROM credit_orders co
)

SELECT
    ib.installment_band,
    COUNT(DISTINCT r.review_id)                             AS total_reviews,
    ROUND(AVG(r.review_score)::NUMERIC, 2)                 AS avg_review_score,
    ROUND(
        COUNT(CASE WHEN r.review_score <= 3 THEN 1 END)::NUMERIC
        / NULLIF(COUNT(r.review_id), 0) * 100
    , 2)                                                    AS pct_low_reviews
FROM installment_bands ib
JOIN reviews r ON ib.order_id = r.order_id
GROUP BY ib.installment_band
ORDER BY CASE ib.installment_band
    WHEN '1'   THEN 1
    WHEN '2-3' THEN 2
    WHEN '4-6' THEN 3
    WHEN '7+'  THEN 4
END;


-- ============================================================
-- TASK 6 — MONTHLY COHORT RETENTION
-- Cohort   : month of customer's first delivered order
-- Retention: % of cohort active in months 0 through 6
-- Output   : matrix with cohorts as rows, month offsets as columns
-- ============================================================
WITH first_orders AS (
    -- Each customer's cohort = month of their very first delivered order
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

customer_activity AS (
    -- All months each customer was active (had a delivered order)
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS activity_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

cohort_activity AS (
    -- Join activity to cohort and compute month offset
    SELECT
        fo.cohort_month,
        ca.customer_unique_id,
        -- Month offset: 0 = cohort month, 1 = one month later, etc.
        EXTRACT(YEAR FROM AGE(ca.activity_month, fo.cohort_month)) * 12
        + EXTRACT(MONTH FROM AGE(ca.activity_month, fo.cohort_month)) AS month_offset
    FROM first_orders fo
    JOIN customer_activity ca ON fo.customer_unique_id = ca.customer_unique_id
    -- Only offsets 0 through 6
    WHERE EXTRACT(YEAR FROM AGE(ca.activity_month, fo.cohort_month)) * 12
          + EXTRACT(MONTH FROM AGE(ca.activity_month, fo.cohort_month)) BETWEEN 0 AND 6
),

cohort_sizes AS (
    -- Count customers per cohort (= month_offset 0 count)
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM cohort_activity
    WHERE month_offset = 0
    GROUP BY cohort_month
),

-- Exclude the most recent (potentially incomplete) month
max_cohort AS (
    SELECT DATE_TRUNC('month', MAX(order_purchase_timestamp)) AS max_month
    FROM orders
    WHERE order_status = 'delivered'
)

-- Pivot: one row per cohort, columns for retention at months 0–6
SELECT
    TO_CHAR(cs.cohort_month, 'YYYY-MM')                     AS cohort,
    cs.cohort_size,
    -- Month 0: always 100%
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 0 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_0,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 1 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_1,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 2 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_2,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 3 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_3,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 4 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_4,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 5 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_5,
    ROUND(
        COUNT(DISTINCT CASE WHEN ca.month_offset = 6 THEN ca.customer_unique_id END)::NUMERIC
        / cs.cohort_size * 100, 2)                          AS month_6
FROM cohort_sizes cs
JOIN cohort_activity ca ON cs.cohort_month = ca.cohort_month
-- Exclude the current (incomplete) month
CROSS JOIN max_cohort mc
WHERE cs.cohort_month < mc.max_month
GROUP BY cs.cohort_month, cs.cohort_size, mc.max_month
ORDER BY cs.cohort_month;
