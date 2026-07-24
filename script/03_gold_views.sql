USE HR_Project;
GO
DROP TABLE IF EXISTS gold.fact_hr_snapshot;
DROP TABLE IF EXISTS gold.dim_emp;
DROP TABLE IF EXISTS gold.dim_position;
DROP TABLE IF EXISTS gold.dim_manager;
DROP TABLE IF EXISTS gold.dim_department;
DROP TABLE IF EXISTS gold.dim_recruitment;
DROP TABLE IF EXISTS gold.dim_performance;
DROP TABLE IF EXISTS gold.dim_emp_status;
GO
-----------DDL - DIMENSIONS (surrogate key = sk_<dimension>, NOT NULL by definition of IDENTITY PKbusiness key   = UNIQUE, so no duplicate surrogate rows for the same source key)
CREATE TABLE gold.dim_emp
(
    sk_emp          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    emp_id          INT UNIQUE,
    emp_name        VARCHAR(100),
    sex             VARCHAR(20),
    dob             DATE,
    marital_desc    VARCHAR(50),
    citizen_desc    VARCHAR(50),
    hispanic_latino VARCHAR(20),
    race_desc       VARCHAR(50),
    state           VARCHAR(50)
);
CREATE TABLE gold.dim_position
(
    sk_position INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    position_id INT UNIQUE,
    position    VARCHAR(100)
);
CREATE TABLE gold.dim_manager
(
    sk_manager   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    manager_id   INT UNIQUE,
    manager_name VARCHAR(100)
);
CREATE TABLE gold.dim_department
(
    sk_department INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    dept_id       INT UNIQUE,
    dept_name     VARCHAR(100)
);
CREATE TABLE gold.dim_recruitment
(
    sk_recruitment          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RecruitmentSource       VARCHAR(100) UNIQUE,
    FromDiversityJobFairID  INT
);
CREATE TABLE gold.dim_performance
(
    sk_performance    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    performance_id    INT UNIQUE,
    performance_score VARCHAR(50)
);
CREATE TABLE gold.dim_emp_status
(
    sk_emp_status INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    empstatus_id  INT UNIQUE,
    emp_status    VARCHAR(100),
    termreason    VARCHAR(255),
    termd         BIT
);
GO
--------DDL - FACT (surrogate key + FKs to dimension surrogate keys)
CREATE TABLE gold.fact_hr_snapshot
(
    sk_hr_snapshot             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    sk_emp                     INT REFERENCES gold.dim_emp(sk_emp),
    sk_position                INT REFERENCES gold.dim_position(sk_position),
    sk_manager                 INT REFERENCES gold.dim_manager(sk_manager),
    sk_department              INT REFERENCES gold.dim_department(sk_department),
    sk_performance             INT REFERENCES gold.dim_performance(sk_performance),
    sk_emp_status              INT REFERENCES gold.dim_emp_status(sk_emp_status),
    sk_recruitment             INT REFERENCES gold.dim_recruitment(sk_recruitment),
    salary                     DECIMAL(18,2),
    absences                   INT,
    dayslatelast30             INT,
    engagementsurvey           DECIMAL(5,2),
    empsatisfaction            INT,
    specialprojectscount       INT,
    date_hiring                DATE,
    date_termination           DATE,
    LastPerformanceReview_Date DATE
);
GO
-----------DML - DIMENSIONS (DISTINCT + surrogate keys are NOT listed/inserted -> SQL Server generates them.)
INSERT INTO gold.dim_emp
(
    emp_id,
    emp_name,
    sex,
    dob,
    marital_desc,
    citizen_desc,
    hispanic_latino,
    race_desc,
    state
)
SELECT DISTINCT
    emp_id,
    emp_name,
    sex,
    dob,
    marital_desc,
    citizen_desc,
    hispanic_latino,
    race_desc,
    state
FROM silver.emp;
GO
INSERT INTO gold.dim_position
(
    position_id,
    position
)
SELECT DISTINCT
    position_id,
    position
FROM silver.position;
GO
INSERT INTO gold.dim_manager
(
    manager_id,
    manager_name
)
SELECT DISTINCT
    manager_id,
    manager_name
FROM silver.manager;
GO
INSERT INTO gold.dim_department
(
    dept_id,
    dept_name
)
SELECT DISTINCT
    dept_id,
    dept_name
FROM silver.department;
GO
INSERT INTO gold.dim_recruitment
(
    RecruitmentSource,
    FromDiversityJobFairID
)
SELECT DISTINCT
    RecruitmentSource,
    FromDiversityJobFairID
FROM silver.recruitment;
GO
INSERT INTO gold.dim_performance
(
    performance_id,
    performance_score
)
SELECT DISTINCT
    performance_id,
    performance_score
FROM silver.performance;
GO
INSERT INTO gold.dim_emp_status
(
    empstatus_id,
    emp_status,
    termreason,
    termd
)
SELECT DISTINCT
    empstatus_id,
    emp_status,
    termreason,
    termd
FROM silver.emp_status;
GO
-------DML - FACT_HR_SNAPSHOT(look up each dimension's surrogate key via its business key)
INSERT INTO gold.fact_hr_snapshot
(
    sk_emp,
    sk_position,
    sk_manager,
    sk_department,
    sk_performance,
    sk_emp_status,
    sk_recruitment,
    salary,
    absences,
    dayslatelast30,
    engagementsurvey,
    empsatisfaction,
    specialprojectscount,
    date_hiring,
    date_termination,
    LastPerformanceReview_Date
)
SELECT
    de.sk_emp,
    dp.sk_position,
    dm.sk_manager,
    dd.sk_department,
    dpf.sk_performance,
    des.sk_emp_status,
    dr.sk_recruitment,
    s.salary,
    s.absences,
    s.dayslatelast30,
    s.engagementsurvey,
    s.empsatisfaction,
    s.specialprojectscount,
    s.date_hiring,
    s.date_termination,
    s.LastPerformanceReview_Date
FROM silver.hr_snapshot s
LEFT JOIN gold.dim_emp         de  ON de.emp_id          = s.emp_id
LEFT JOIN gold.dim_position    dp  ON dp.position_id     = s.position_id
LEFT JOIN gold.dim_manager     dm  ON dm.manager_id       = s.manager_id
LEFT JOIN gold.dim_department  dd  ON dd.dept_id          = s.dept_id
LEFT JOIN gold.dim_performance dpf ON dpf.performance_id  = s.performance_id
LEFT JOIN gold.dim_emp_status  des ON des.empstatus_id     = s.empstatus_id
LEFT JOIN gold.dim_recruitment dr  ON dr.RecruitmentSource = s.RecruitmentSource;
GO 
---------------VALIDATION
SELECT
'Silver HR Snapshot' AS Layer,
COUNT(*) AS Row_Count
FROM silver.hr_snapshot
UNION ALL
SELECT
'Gold Fact HR Snapshot',
COUNT(*)
FROM gold.fact_hr_snapshot;
GO
SELECT * FROM gold.fact_hr_snapshot
WHERE sk_emp IS NULL OR sk_position IS NULL OR sk_department IS NULL
   OR sk_manager IS NULL OR sk_performance IS NULL OR sk_emp_status IS NULL
   OR sk_recruitment IS NULL;

   SELECT EmpID, Employee_Name, ManagerID, ManagerName, Position
FROM bronze.hr_data
WHERE TRY_CAST(TRIM(EmpID) AS INT) IN (277, 184, 154, 136, 214, 77, 11, 71);