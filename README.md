# HR Data Warehouse & Analytics Project

> A complete **Medallion Architecture (Bronze → Silver → Gold)** data warehouse built on SQL Server, transforming a single flat HR CSV extract into a governed, analysis-ready star schema, automated via SQL Server Agent, and consumed through a 4-page Power BI report.

![SQL Server](https://img.shields.io/badge/SQL%20Server-Data%20Warehouse-red)
![T-SQL](https://img.shields.io/badge/T--SQL-ETL-blue)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-informational)

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [ETL Pipeline & Automation](#-etl-pipeline--automation)
- [Repository Structure](#-repository-structure)
- [Installation & Setup](#-installation--setup)
- [Data Dictionary](#-data-dictionary)
- [Power BI Dashboard](#-power-bi-dashboard)
- [Data Validation](#-data-validation)
- [Known Limitations](#-known-limitations)
- [Roadmap](#-roadmap)
- [Contributors](#-contributors)
- [License](#-license)

---

## 📊 Overview

HR departments typically hold employee data — demographics, compensation, performance, recruitment source, tenure, and termination reasons — in a single flat operational file that isn't prepared for analysis.

This project converts that flat file into a governed, three-layer data warehouse, enabling reliable, repeatable, self-service HR reporting instead of ad-hoc spreadsheet manipulation.

### Key Facts

| Item | Details |
|---|---|
| Source dataset | `HRDataset_v14` |
| Records | **311 employees** |
| Source columns | **36** |
| Grain | One row per employee |
| Architecture | **Medallion: Bronze → Silver → Gold** |
| Database | Microsoft SQL Server |
| ETL | T-SQL |
| Automation | SQL Server Agent |
| Reporting | Power BI |
| Gold layer | 5 dimension views + 1 fact view |

### Medallion Architecture

| Layer | Description |
|---|---|
| 🥉 **Bronze** | Raw, unmodified copy of the source CSV loaded via `BULK INSERT`. Every column is `VARCHAR(MAX)` with no type casting or cleaning. |
| 🥈 **Silver** | Cleaned, standardized, type-cast, deduplicated, and conformed physical tables. Primary Keys are defined here. This is the single source of truth. |
| 🥇 **Gold** | Business-ready analytical SQL Views built directly on Silver: 5 dimension views + 1 fact view. No physical Gold tables and no surrogate keys. |

> **Implementation note:** The Gold layer is implemented as **Views**, not physical tables. Views avoid duplicating data already governed in Silver, keep business logic centralized, and allow Power BI to query a simplified presentation-ready structure that always reflects the current state of Silver.

---

# 🏗️ Architecture

## High-Level Architecture

```mermaid
flowchart LR
    A[📄 HR Dataset<br/>HRDataset_v14.csv]
    --> B[🥉 Bronze Layer<br/>bronze.hr_data<br/>Raw / VARCHAR / No transformation]

    B --> C[🥈 Silver Layer<br/>8 cleaned & conformed tables<br/>Primary Keys defined here]

    C --> D[🥇 Gold Layer<br/>Analytical SQL Views<br/>No physical tables / No surrogate keys]

    D --> E[📊 Power BI<br/>4-page report]
    D --> F[🔎 Ad-hoc SQL<br/>Analytical querying]