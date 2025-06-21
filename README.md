# Supply-chain

# 📊 Customer Order Performance & Delivery Analysis with SQL

## 🧾 Introduction

This project explores customer order and delivery performance using SQL, analyzing data from various tables such as `fact_order_lines`, `dim_customers`, `dim_products`, and others. The goal is to evaluate how well orders were placed, fulfilled, and delivered across time periods and customer segments.

## ❓ Problem Statement

Timely and complete delivery of customer orders is critical for customer satisfaction and operational efficiency. However, businesses often struggle with delayed or partial deliveries. This project aims to:

- Analyze on-time and in-full (OTIF) delivery performance.
- Identify trends and outliers.
- Compare actual delivery performance to target KPIs.
- Recommend actionable insights based on customer and product performance.

## 📁 Dataset Overview

Key tables used:
- `fact_order_lines`: Contains detailed records of each order including placement and delivery dates.
- `dim_customers`: Customer demographics and location data.
- `dim_products`: Product category and details.
- `dim_targets_orders`: Target KPIs for OTIF performance.
- `dim_date`: Date dimension for calendar-based aggregations.

## ⚙️ SQL Analysis Summary

### 📅 Date-based Order Analysis
- Extracted year, month, and day from `order_placement_date`.
- Counted monthly, weekly, and daily orders.
- Identified busiest and slowest weeks/months.
- Evaluated orders placed on weekends vs weekdays.

### 🚚 Delivery Performance
- Measured days between placement and actual delivery.
- Analyzed OTIF (on-time-in-full) delivery metrics.
- Highlighted early, on-time, and late deliveries.
- Tracked late delivery trends weekly and monthly.

### 📈 Target Comparison
- Evaluated customers' performance against `ontime_target_percent` and `infull_target_percent`.
- Flagged customers performing below 80% of their target KPIs.
- Identified top and bottom product categories in OTIF performance.

### 🛍 Product and Customer Insights
- Top product categories by order volume.
- Customers exceeding or falling short of targets.
- Monthly OTIF trend per customer.

## 💡 Recommendations

1. **Focus on Low-Performing Customers**: Use CTE-based reports to follow up with customers below 80% of delivery targets.
2. **Optimize Busiest Weeks**: Increase logistical resources during peak order weeks.
3. **Product Performance Monitoring**: Regularly review top and bottom-performing product categories to identify bottlenecks.
4. **Refine Delivery Processes**: Improve scheduling to minimize late deliveries.

## ✅ Conclusion

This SQL-based analysis helps uncover vital trends and inefficiencies in customer order handling. Through structured queries, we've identified opportunities to enhance delivery performance, customer satisfaction, and product strategy alignment. This analysis can be extended using dashboards for real-time business intelligence.

---

🔍 Built using:
- Microsoft SQL Server 
