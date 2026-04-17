# 📊 End-to-End Supply Chain KPI & Inventory Optimization Analysis (SQL)

## 📌 Project Overview

This project analyses end-to-end supply chain data to evaluate product performance, inventory efficiency, and component-level risks. Using SQL, data from sales orders, bill of materials (BOM), and procurement is integrated to generate actionable insights for supply chain decision-making.

The goal is to simulate real-world supply chain analysis by linking demand, supply, and inventory behavior.

---

## 🎯 Objectives

- Monitor and evaluate inventory levels to ensure optimal stock performance  
- Analyse order fulfillment processes and identify potential delays impacting service levels  
- Detect risks of stockouts and overstock through data-driven analysis  
- Support supply chain decision-making through KPI-driven insights  

---

## 📂 Data Sources

This project integrates multiple datasets:

- **Sales Orders** → Demand data  
- **Bill of Materials (BOM)** → Component usage per product  
- **Purchase Orders (PO)** → Supply data  
- **Components / Products / Vendors / Customers** → Master data  

---

## 🛠️ Tools Used

- SQL (window functions, joins, aggregations)  
- SQLite (data storage and querying)  

---

# 📊 Key Analysis & Insights

---

## 🔹 1. Product Revenue & ABC Analysis

### Approach
- Calculated total revenue per product (`quantity × unit_price`)  
- Ranked products by revenue contribution  
- Computed revenue share using window functions  

### Key Insight
- A small number of products generate the majority of total revenue  
- Revenue distribution follows the **Pareto principle (80/20 rule)**  

### Business Impact
- Prioritize high-revenue products for:
  - Inventory availability  
  - Forecast accuracy  
  - Service level monitoring  

📸 *Screenshot: `/screenshots/revenue_analysis.png`*

---

## 🔹 2. Cumulative Revenue (Pareto Analysis)

### Approach
- Calculated cumulative revenue in descending order  
- Computed percentage contribution of each product  
- Identified threshold where top products reach ~80% of revenue  

### Key Insight
- Top-performing products quickly accumulate the majority of total revenue  

### Business Classification
- **A items** → High priority (major revenue contributors)  
- **B items** → Medium importance  
- **C items** → Low impact  

### Business Impact
- Enables targeted inventory planning  
- Focus resources on critical SKUs  
- Improves demand forecasting efficiency  

📸 *Screenshot: `/screenshots/pareto_analysis.png`*

---

## 🔹 3. Component Aging & Inventory Turnover Analysis

### Approach
- Integrated:
  - Sales Orders (demand)  
  - BOM (component consumption)  
  - Purchase Orders (supply)  

- Calculated:
  - Total received vs consumed  
  - Current stock levels  
  - Inventory turnover rate  

- Classified components:
  - Slow-moving (aging risk)  
  - Normal  
  - Fast-moving  

### Key Insight
- Identified components with low turnover → excess inventory risk  
- Identified high-turnover components → potential stockout risk  

### Business Impact
- Reduce excess inventory and improve working capital  
- Optimize procurement decisions  
- Improve supply-demand alignment  

📸 *Screenshot: `/screenshots/inventory_turnover.png`*

---

# 📈 Overall Business Value

This analysis provides:

- Improved visibility into supply chain performance  
- Identification of inefficiencies in inventory management  
- Data-driven support for:
  - Inventory optimization  
  - Demand planning  
  - Supplier coordination  

---

# 🧠 Key Takeaways

- Revenue is concentrated in a small subset of products → prioritize them  
- Inventory imbalance exists between supply and demand  
- Some components show aging risk → opportunity to reduce excess stock  
- Data-driven insights can significantly improve planning decisions

- # 🚀 Future Improvements

- Build Power BI dashboard for KPI visualization  
- Add demand forecasting model (Python)  
- Extend analysis with service level and lead time variability  

---

# 👤 Author

**An Truong**  
Supply Chain & Data Analytics Enthusiast  
Helsinki, Finland  
