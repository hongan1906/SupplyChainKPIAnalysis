---Revenue & product performance
WITH ProductRevenue AS (
    SELECT 
        product_id,
        SUM(quantity * unit_price) as total_revenue
    FROM sales_orders
    GROUP BY product_id
),
RevenueShare AS (
    SELECT 
        product_id,
        total_revenue,
        SUM(total_revenue) OVER() as grand_total,
        CAST(total_revenue AS FLOAT) / SUM(total_revenue) OVER() as revenue_pct
    FROM ProductRevenue
)
SELECT * FROM RevenueShare 
ORDER BY total_revenue DESC;

----Cumulative Revenue

WITH ProductRevenue AS (
    SELECT 
        product_id,
        SUM(quantity * unit_price) as total_revenue
    FROM sales_orders
    GROUP BY product_id
),
CumulativeAnalysis AS (
    SELECT 
        product_id,
        total_revenue,
        -- Calculate cumulative revenue from highest to lowest
        SUM(total_revenue) OVER(ORDER BY total_revenue DESC) as cumulative_revenue,
        -- Calculate total revenue across the entire system
        SUM(total_revenue) OVER() as grand_total
    FROM ProductRevenue
)
SELECT 
    product_id,
    total_revenue,
    -- Calculate cumulative percentage contribution
    ROUND((cumulative_revenue / grand_total) * 100, 2) as cumulative_pct
FROM CumulativeAnalysis
ORDER BY total_revenue DESC;

----- Aging Components
WITH ComponentUsage AS (
    -- Bước 1: Calculate total component consumption based on sales and BOM
    SELECT 
        b.component_id,
        SUM(s.quantity * b.quantity) AS total_used
    FROM sales_orders s
    JOIN bom b ON s.product_id = b.product_id
    GROUP BY b.component_id
),
ComponentReceived AS (
    -- Bước 2: Calculate total component receipts from purchase orders
    SELECT 
        component_id,
        SUM(delivered_qty) AS total_received
    FROM po_lines
    GROUP BY component_id
),
InventoryTurnover AS (
    -- Bước 3: Calculate inventory levels and turnover rate
    SELECT 
        c.component_id,
        c.component_name,
        c.category,
        COALESCE(r.total_received, 0) AS imported_qty,
        COALESCE(u.total_used, 0) AS consumed_qty,
        (COALESCE(r.total_received, 0) - COALESCE(u.total_used, 0)) AS current_stock,
        --  Inventory turnover ratio = consumption / received quantity
        CASE 
            WHEN COALESCE(r.total_received, 0) = 0 THEN 0 
            ELSE CAST(COALESCE(u.total_used, 0) AS FLOAT) / r.total_received 
        END AS turnover_rate
    FROM components c
    LEFT JOIN ComponentReceived r ON c.component_id = r.component_id
    LEFT JOIN ComponentUsage u ON c.component_id = u.component_id
)
-- Bước 4: Classify components based on turnover rate (aging analysis)
SELECT *,
    CASE 
        WHEN turnover_rate < 0.2 THEN 'Slow Moving / High Aging'
        WHEN turnover_rate BETWEEN 0.2 AND 0.6 THEN 'Normal'
        ELSE 'Fast Moving'
    END AS aging_status
FROM InventoryTurnover
ORDER BY turnover_rate ASC;
