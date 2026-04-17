# Supply Chain & Sales Analytics SQL Library

This repository contains a collection of SQL queries designed for manufacturing analytics. The scripts focus on identifying revenue drivers and optimizing inventory health through component-level analysis.

## 📊 Modules

### 1. Revenue Concentration Analysis
This module provides insights into how revenue is distributed across your product catalog.

* **Product Revenue Share:** Calculates the total revenue per product and its percentage contribution to the total grand revenue.
* **Cumulative Revenue (Pareto Analysis):** Ranks products by revenue and calculates a running total percentage. This is essential for identifying the "Top 20%" products that typically drive 80% of business value.

### 2. Inventory & Component Aging
A deep dive into the Bill of Materials (BOM) and Purchase Orders (PO) to identify "dead stock" or slow-moving raw materials.

* **Logic:** It maps sales back to the component level (via BOM) and compares actual consumption against warehouse intake (via POs).
* **Aging Status Classification:**
    * 🔴 **Slow Moving / High Aging:** Turnover rate < 20% (High risk of obsolescence).
    * 🟡 **Normal:** Turnover rate between 20% and 60%.
    * 🟢 **Fast Moving:** Turnover rate > 60% (High demand components).

---

## 🗄️ Database Schema
The queries assume the existence of the following relational structure:

| Table | Key Columns | Description |
| :--- | :--- | :--- |
| `sales_orders` | `product_id`, `quantity`, `unit_price` | Customer transaction data. |
| `bom` | `product_id`, `component_id`, `quantity` | Recipe/Bill of Materials for products. |
| `po_lines` | `component_id`, `delivered_qty` | Intake of raw materials from suppliers. |
| `components` | `component_id`, `component_name`, `category` | Master list of raw materials. |

---


---

## 🛠 Usage
Each script is self-contained. You can execute them in your SQL workbench (PostgreSQL, SQL Server, BigQuery, etc.) to generate reports for supply chain management or financial auditing.
