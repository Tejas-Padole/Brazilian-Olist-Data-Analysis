<div align="center">

# 🛒 Olist E-Commerce SQL Analytics

**Production-ready SQL business intelligence report on 100k+ Brazilian e-commerce orders**

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-336791?style=flat&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL%20only-blue?style=flat)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20%7C%20Kaggle-orange?style=flat)
![Tasks](https://img.shields.io/badge/Tasks-6%20%7C%2016%20sub--tasks-green?style=flat)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat)

</div>

---

## 📌 Overview

This project simulates a real **Senior Data Analyst** assignment at Olist — the largest department store in Brazilian marketplaces. The goal is to deliver a comprehensive performance diagnosis to the CEO covering revenue, customers, sellers, logistics, payments, and retention.

Every answer is written **exclusively in SQL** — no Python, no BI tool, no shortcuts. Just clean, well-commented, production-ready PostgreSQL.

---

## 📊 Schema

![Olist ERD](schema/erd.png)

> 9 tables · ~100,000 orders · Brazilian e-commerce data from 2016–2018

---

## 🗂️ Dataset

| | |
|---|---|
| **Source** | [Brazilian E-Commerce Public Dataset — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| **Size** | ~100k orders, ~100k customers, ~3k sellers |
| **Period** | September 2016 – October 2018 |
| **License** | CC BY-NC-SA 4.0 |

---

## 🎯 Tasks at a Glance

| # | Task | Business Question | Key SQL Pattern |
|---|------|-------------------|-----------------|
| 1 | **Revenue & Category Intelligence** | Which categories drive revenue? How is growth trending? | `LAG()`, `DENSE_RANK()`, conditional aggregation |
| 2 | **RFM Customer Segmentation** | Who are our best customers? | `NTILE(5)`, recency/frequency/monetary scoring |
| 3 | **Seller Performance** | Which sellers are underperforming statistically? | `RANK()`, `STDDEV()`, `CROSS JOIN` benchmark |
| 4 | **Geo & Shipping Analysis** | How does location affect delivery and satisfaction? | Late delivery flag, state-level aggregation |
| 5 | **Payment Behavior** | How do payment methods and installments affect reviews? | Value bins, `CASE` bucketing |
| 6 | **Cohort Retention** | How well do we retain customers month over month? | `DATE_TRUNC`, pivot with `CASE WHEN` |

---

## 🔍 Task Details

<details>
<summary><strong>Task 1 — Revenue & Category Intelligence</strong></summary>

- **1.1** Total revenue and order count per English product category (delivered orders only)
- **1.2** Month-over-month revenue growth for the top 5 categories over the last 12 months
- **1.3** Top 3 products by revenue within each of the top 5 categories
- **1.4** Average review score and % of low reviews (score ≤ 3) for those top products

</details>

<details>
<summary><strong>Task 2 — RFM Customer Segmentation</strong></summary>

Builds a complete **Recency · Frequency · Monetary** model:
- Recency = days since last order (reference date: `2018-10-17`)
- Frequency = total delivered orders
- Monetary = total spend
- Each metric scored 1–5 using `NTILE(5)` quintiles
- Output: top 10 customers with RFM score (e.g. `5-4-5`), city, and state

</details>

<details>
<summary><strong>Task 3 — Seller Performance & Underperformers</strong></summary>

- **3.1** Per-seller KPIs: revenue, avg delivery days, avg review score, total orders
- **3.2** Rank sellers within each state by revenue using `RANK()`
- **3.3** Flag statistical underperformers: avg delivery > (mean + 2 × stddev) AND review score below average

</details>

<details>
<summary><strong>Task 4 — Geographical & Shipping Analysis</strong></summary>

- **4.1** Per-state: revenue, unique customers, avg delivery time, % late deliveries
- **4.2** Top 5 cities by avg review score (minimum 50 orders)
- **4.3** Same-state vs cross-state comparison: avg delivery time and avg freight value

</details>

<details>
<summary><strong>Task 5 — Payment Behavior & Installments</strong></summary>

- **5.1** Most common payment type overall
- **5.2** Order value bins (0–50, 50–100, 100–200, 200–500, 500+) → avg installments and % credit card
- **5.3** Installment bands (1, 2–3, 4–6, 7+) → avg review score and % of low reviews

</details>

<details>
<summary><strong>Task 6 — Monthly Cohort Retention</strong></summary>

Full cohort retention matrix — cohorts as rows, month offsets 0–6 as columns:

```
cohort    | size | month_0 | month_1 | month_2 | month_3 | month_4 | month_5 | month_6
----------|------|---------|---------|---------|---------|---------|---------|--------
2017-01   |  302 | 100.00  |   3.97  |   1.99  |   1.32  |   0.99  |   0.66  |  0.33
2017-02   |  481 | 100.00  |   4.16  |   2.08  |   1.46  |   1.04  |   0.83  |  0.62
2017-03   |  683 | 100.00  |   3.81  |   1.76  |   1.17  |   0.88  |   0.73  |  0.44
```

</details>

---

## 🧠 SQL Concepts Reference

| Concept | Used In | Purpose |
|---|---|---|
| `WITH` (CTE) | All tasks | Readable, modular query structure |
| `DATE_TRUNC('month', ts)` | Tasks 1.2, 6 | Group timestamps by month |
| `LAG()` | Task 1.2 | Access previous row for MoM growth |
| `DENSE_RANK()` | Tasks 1.3, 3.2 | Rank without skipping on ties |
| `NTILE(5)` | Task 2 | Split into 5 equal quintile buckets |
| `CASE WHEN` in `COUNT` | Tasks 1.4, 4.1, 5.2, 5.3, 6 | Count matching rows without filtering |
| `NULLIF(x, 0)` | Tasks 1.2, 1.4, 4.1+ | Safe division, prevent zero errors |
| `STDDEV()` | Task 3.3 | Statistical outlier threshold |
| `CROSS JOIN` (1-row) | Task 3.3 | Broadcast benchmark to all rows |
| `AGE(ts1, ts2)` | Tasks 3, 4, 6 | PostgreSQL interval arithmetic |
| `EXTRACT(DAY FROM AGE(...))` | Tasks 3.1, 4.1, 4.3 | Convert interval to numeric days |

---

## ⚙️ How to Run

### 1. Get the data

Download from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and load into PostgreSQL:

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

### 2. Run the analysis

```bash
psql -U your_user -d your_db -f olist_analytics.sql
```

Or open `olist_analytics.sql` in DBeaver / DataGrip / TablePlus and run each task block individually.

### 3. PostgreSQL version note

Task 2 uses `QUALIFY` (PostgreSQL 15+). On older versions, replace with:

```sql
SELECT * FROM (
  SELECT ..., ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY customer_id) AS rn
  FROM ...
) sub WHERE rn = 1
```

---

## 📐 Core Assumptions

| Assumption | Rule |
|---|---|
| Revenue | `SUM(price)` — excludes `freight_value` unless stated |
| Date reference | `order_purchase_timestamp` for all temporal analysis |
| Delivered filter | `order_status = 'delivered'` for Tasks 1–4 |
| Reviews scope | All orders considered (Tasks 4.2, 5.3) |
| RFM reference date | `2018-10-17` |
| Delivery time | `EXTRACT(DAY FROM AGE(order_delivered_customer_date, order_purchase_timestamp))` |
| Late delivery | `order_delivered_customer_date > order_estimated_delivery_date` |
| Customer identity | `customer_unique_id` tracks same person across multiple orders |

---

## 📁 Repository Structure

```
olist-sql-analytics/
│
├── olist_analytics.sql    ← All 6 tasks, 16 sub-tasks, fully commented
├── README.md
└── schema/
    └── erd.png            ← Entity-relationship diagram
```

---

## 📝 License

This project is licensed under the **MIT License**.  
The Olist dataset is available under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

---

<div align="center">

⭐ If this helped you prep for a data analyst interview, give it a star!

</div>
