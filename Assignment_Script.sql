/* =====================================================================
   End-to-End Supply Chain KPI & Inventory Analysis
   Engine: SQLite
   Tables: sales_orders, bom, po_lines, components
   ===================================================================== */


/* ---------------------------------------------------------------------
   1. Product revenue & revenue share
   --------------------------------------------------------------------- */
WITH product_revenue AS (
    SELECT
        product_id,
        SUM(quantity * unit_price) AS total_revenue
    FROM sales_orders
    GROUP BY product_id
)
SELECT
    product_id,
    total_revenue,
    ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) AS revenue_pct,
    RANK() OVER (ORDER BY total_revenue DESC)                   AS revenue_rank
FROM product_revenue
ORDER BY total_revenue DESC;


/* ---------------------------------------------------------------------
   2. Pareto (cumulative revenue) & ABC classification
      A = products making up the first 80% of revenue
      B = next 15% (80–95%)
      C = remaining 5%
   --------------------------------------------------------------------- */
WITH product_revenue AS (
    SELECT
        product_id,
        SUM(quantity * unit_price) AS total_revenue
    FROM sales_orders
    GROUP BY product_id
),
cumulative AS (
    SELECT
        product_id,
        total_revenue,
        -- ROWS frame + tie-breaker so products with equal revenue
        -- get distinct, correctly ordered cumulative totals
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                              AS cumulative_revenue,
        SUM(total_revenue) OVER ()     AS grand_total
    FROM product_revenue
)
SELECT
    product_id,
    total_revenue,
    -- 100.0 forces floating-point division (integer division in SQLite would return 0)
    ROUND(100.0 * total_revenue      / grand_total, 2) AS revenue_pct,
    ROUND(100.0 * cumulative_revenue / grand_total, 2) AS cumulative_pct,
    CASE
        WHEN 100.0 * (cumulative_revenue - total_revenue) / grand_total < 80 THEN 'A'
        WHEN 100.0 * (cumulative_revenue - total_revenue) / grand_total < 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM cumulative
ORDER BY total_revenue DESC;


/* ABC summary: how many products sit in each class and their revenue share */
WITH product_revenue AS (
    SELECT product_id, SUM(quantity * unit_price) AS total_revenue
    FROM sales_orders
    GROUP BY product_id
),
cumulative AS (
    SELECT
        product_id,
        total_revenue,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS grand_total
    FROM product_revenue
),
classified AS (
    SELECT
        *,
        CASE
            WHEN 100.0 * (cumulative_revenue - total_revenue) / grand_total < 80 THEN 'A'
            WHEN 100.0 * (cumulative_revenue - total_revenue) / grand_total < 95 THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM cumulative
)
SELECT
    abc_class,
    COUNT(*)                                                         AS product_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)               AS pct_of_products,
    ROUND(100.0 * SUM(total_revenue) / MAX(grand_total), 1)          AS pct_of_revenue
FROM classified
GROUP BY abc_class
ORDER BY abc_class;


/* ---------------------------------------------------------------------
   3. Component consumption vs. receipts (slow-moving / excess stock risk)
      Demand is exploded through the BOM:
        component demand = product units sold × component qty per unit
   --------------------------------------------------------------------- */
WITH component_usage AS (
    SELECT
        b.component_id,
        SUM(s.quantity * b.quantity) AS total_used
    FROM sales_orders s
    JOIN bom b ON s.product_id = b.product_id
    GROUP BY b.component_id
),
component_received AS (
    SELECT
        component_id,
        SUM(delivered_qty) AS total_received
    FROM po_lines
    GROUP BY component_id
),
component_balance AS (
    SELECT
        c.component_id,
        c.component_name,
        c.category,
        c.unit_cost,
        COALESCE(r.total_received, 0)                                AS received_qty,
        COALESCE(u.total_used, 0)                                    AS consumed_qty,
        COALESCE(r.total_received, 0) - COALESCE(u.total_used, 0)    AS net_stock,
        -- Value of the period balance (working capital tied up when positive)
        ROUND((COALESCE(r.total_received, 0) - COALESCE(u.total_used, 0)) * c.unit_cost, 2)
                                                                     AS net_stock_value,
        -- Share of received quantity that was consumed by demand
        CASE
            WHEN COALESCE(r.total_received, 0) = 0 THEN NULL
            ELSE ROUND(1.0 * COALESCE(u.total_used, 0) / r.total_received, 3)
        END                                                          AS consumption_ratio
    FROM components c
    LEFT JOIN component_received r ON c.component_id = r.component_id
    LEFT JOIN component_usage    u ON c.component_id = u.component_id
)
SELECT
    *,
    CASE
        WHEN received_qty = 0 AND consumed_qty = 0 THEN 'No activity'
        WHEN received_qty = 0                      THEN 'Demand without receipts (check data)'
        WHEN net_stock < 0                         THEN 'Shortage / missing opening stock'
        WHEN consumption_ratio < 0.2               THEN 'Slow-moving (excess risk)'
        WHEN consumption_ratio < 0.6               THEN 'Normal'
        ELSE                                            'Fast-moving (stockout risk)'
    END AS movement_status
FROM component_balance
ORDER BY consumption_ratio ASC;
