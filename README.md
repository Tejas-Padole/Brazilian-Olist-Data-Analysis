<div align="center">

# 🛒 Olist E-Commerce SQL Analytics

**Deep-diving into 100k+ Brazilian e-commerce orders using pure SQL**

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-336791?style=flat&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL%20only-blue?style=flat)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20%7C%20Kaggle-orange?style=flat)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat)

</div>

---

## 👋 About This Project

I built this project to sharpen my SQL skills on a real-world e-commerce dataset. The [Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle covers ~100k orders placed on the largest Brazilian marketplace between 2016 and 2018 — with tables for customers, sellers, products, payments, reviews, and geography.

Instead of using Python or a BI tool, I challenged myself to answer every business question in **pure PostgreSQL** — from basic aggregations all the way to RFM segmentation, statistical outlier detection, and cohort retention matrices.

Here's what I explored across 6 analysis areas:

- 📈 **Which product categories drive the most revenue — and how is that changing month over month?**
- 👥 **Who are the most valuable customers, based on how recently, how often, and how much they buy?**
- 🏪 **Which sellers are consistently late and getting poor reviews — and are they statistical outliers?**
- 🌍 **How does a customer's state affect their delivery experience and satisfaction?**
- 💳 **Does paying in more installments correlate with worse review scores?**
- 📆 **What does customer retention actually look like — how many come back after month 1?**

Everything is written in a single well-commented SQL file, structured with CTEs so each step is readable and easy to follow.

---

## 🗂️ Dataset

| | |
|---|---|
| **Source** | [Brazilian E-Commerce Public Dataset — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| **Size** | ~100k orders, ~100k customers, ~3k sellers |
| **Period** | September 2016 – October 2018 |
| **License** | CC BY-NC-SA 4.0 |

---

## 🎯 What's Inside

| # | Analysis | Key SQL Used |
|---|----------|--------------|
| 1 | Revenue & category intelligence | `LAG()`, `DENSE_RANK()`, conditional aggregation |
| 2 | RFM customer segmentation | `NTILE(5)`, quintile scoring |
| 3 | Seller performance & outliers | `RANK()`, `STDDEV()`, `CROSS JOIN` benchmark |
| 4 | Geo & shipping analysis | Late delivery flag, state-level aggregation |
| 5 | Payment behavior & installments | Value bins, `CASE` bucketing |
| 6 | Monthly cohort retention | `DATE_TRUNC`, pivot with `CASE WHEN` |

---

## 🔍 Analysis Breakdown

<details>
<summary><strong>1 — Revenue & Category Intelligence</strong></summary>

- Total revenue and order count per product category (English names, delivered orders only)
- Month-over-month revenue growth for the top 5 categories over the last 12 months
- Top 3 products by revenue within each of those top 5 categories
- Average review score and % of low reviews (≤ 3 stars) for each of those products

</details>

<details>
<summary><strong>2 — RFM Customer Segmentation</strong></summary>

Built a full **Recency · Frequency · Monetary** model to identify the most valuable customers:

- Recency = days since last order (reference: `2018-10-17`)
- Frequency = total delivered orders per customer
- Monetary = total spend per customer
- Each metric scored 1–5 using `NTILE(5)` quintiles
- Final output: top 10 customers ranked by combined RFM score, with city and state

</details>

<details>
<summary><strong>3 — Seller Performance & Outliers</strong></summary>

- Per-seller KPIs: revenue, avg delivery days, avg review score, total orders
- Sellers ranked within each state by revenue
- Flagged statistical underperformers: sellers whose avg delivery time exceeds mean + 2×stddev **and** whose avg review score is below the platform average

</details>

<details>
<summary><strong>4 — Geographical & Shipping Analysis</strong></summary>

- Per-state breakdown: revenue, unique customers, avg delivery time, % late deliveries
- Top 5 cities by average review score (cities with at least 50 orders only)
- Compared same-state vs cross-state orders on avg delivery time and avg freight cost

</details>

<details>
<summary><strong>5 — Payment Behavior & Installments</strong></summary>

- Most common payment type across all orders
- Bucketed orders by total value (0–50, 50–100, 100–200, 200–500, 500+) and looked at avg installments and % paid by credit card per bucket
- Grouped credit card orders by installment count (1, 2–3, 4–6, 7+) and compared avg review score and % of low reviews per group

</details>

<details>
<summary><strong>6 — Monthly Cohort Retention</strong></summary>

Built a retention matrix tracking what % of each monthly cohort placed another order in months 1 through 6 after their first purchase:

```
cohort    | size | month_0 | month_1 | month_2 | month_3 | month_4 | month_5 | month_6
----------|------|---------|---------|---------|---------|---------|---------|--------
2017-01   |  302 | 100.00  |   3.97  |   1.99  |   1.32  |   0.99  |   0.66  |  0.33
2017-02   |  481 | 100.00  |   4.16  |   2.08  |   1.46  |   1.04  |   0.83  |  0.62
2017-03   |  683 | 100.00  |   3.81  |   1.76  |   1.17  |   0.88  |   0.73  |  0.44
```

</details>

---

## 🧠 SQL Concepts Used

| Concept | Where | What it does |
|---|---|---|
| `WITH` (CTE) | All analyses | Breaks complex logic into named, readable steps |
| `DATE_TRUNC('month', ts)` | Analyses 1, 6 | Collapses timestamps to month granularity |
| `LAG()` | Analysis 1 | Looks back one row to compute MoM growth |
| `DENSE_RANK()` | Analyses 1, 3 | Ranks rows without skipping numbers on ties |
| `NTILE(5)` | Analysis 2 | Splits customers into 5 equal scoring buckets |
| `CASE WHEN` inside `COUNT` | Analyses 1, 4, 5, 6 | Counts only rows matching a condition |
| `NULLIF(x, 0)` | Multiple | Prevents division-by-zero errors cleanly |
| `STDDEV()` | Analysis 3 | Computes standard deviation for outlier threshold |
| `CROSS JOIN` (single row) | Analysis 3 | Broadcasts a benchmark value across all seller rows |
| `AGE(ts1, ts2)` | Analyses 3, 4, 6 | PostgreSQL interval arithmetic between timestamps |
| `EXTRACT(DAY FROM AGE(...))` | Analyses 3, 4 | Converts a time interval into numeric days |

---

## ⚙️ How to Run

### 1. Get the data

Download from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and load all CSVs into PostgreSQL:

```bash
psql -U your_user -d your_db -c "\copy orders FROM 'olist_orders_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy order_items FROM 'olist_order_items_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy customers FROM 'olist_customers_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy products FROM 'olist_products_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy sellers FROM 'olist_sellers_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy payments FROM 'olist_order_payments_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy reviews FROM 'olist_order_reviews_dataset.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy category_translation FROM 'product_category_name_translation.csv' CSV HEADER"
psql -U your_user -d your_db -c "\copy geolocation FROM 'olist_geolocation_dataset.csv' CSV HEADER"
```

### 2. Run the queries

```bash
psql -U your_user -d your_db -f olist_analytics.sql
```

Or open `olist_analytics.sql` in any SQL client (DBeaver, DataGrip, TablePlus) and run each section individually.

> **Note:** Analysis 2 uses `QUALIFY` which requires PostgreSQL 15+. On older versions, wrap the final SELECT in a subquery and add `WHERE rn = 1`.

---

## 📐 Assumptions & Definitions

| | |
|---|---|
| Revenue | `SUM(price)` from `order_items` — freight excluded unless stated |
| Date column | `order_purchase_timestamp` used for all time-based analysis |
| Delivered only | `order_status = 'delivered'` applied to all revenue and delivery analyses |
| Delivery time | `EXTRACT(DAY FROM AGE(order_delivered_customer_date, order_purchase_timestamp))` |
| Late delivery | `order_delivered_customer_date > order_estimated_delivery_date` |
| RFM reference date | `2018-10-17` |
| Customer identity | `customer_unique_id` used to track the same person across multiple orders |

---

## 📁 Repository Structure

```
olist-sql-analytics/
│
├── olist_analytics.sql    ← All 6 analyses, fully commented
├── README.md
└── schema/
    └── erd.png            ← Database schema diagram
```

---

## 📝 License

MIT — dataset via [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

---

<div align="center">

If you find this useful, feel free to ⭐ the repo!

</div>
