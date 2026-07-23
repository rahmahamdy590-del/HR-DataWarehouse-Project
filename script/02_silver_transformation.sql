USE HR_Project;
GO

DROP TABLE IF EXISTS silver.hr_snapshot;
DROP TABLE IF EXISTS silver.emp;
DROP TABLE IF EXISTS silver.position;
DROP TABLE IF EXISTS silver.manager;
DROP TABLE IF EXISTS silver.department;
DROP TABLE IF EXISTS silver.recruitment;
DROP TABLE IF EXISTS silver.performance;
DROP TABLE IF EXISTS silver.emp_status;
GO

/*==========================
DDL
==========================*/

CREATE TABLE silver.emp
(
    emp_id INT,
    emp_name VARCHAR(100),
    sex VARCHAR(20),
    dob DATE,
    marital_desc VARCHAR(50),
    citizen_desc VARCHAR(50),
    hispanic_latino VARCHAR(20),
    race_desc VARCHAR(50),
    state VARCHAR(50)
);

CREATE TABLE silver.position
(
    position_id INT,
    position VARCHAR(100)
);

CREATE TABLE silver.manager
(
    manager_id INT,
    manager_name VARCHAR(100)
);

CREATE TABLE silver.department
(
    dept_id INT,
    dept_name VARCHAR(100)
);

CREATE TABLE silver.recruitment
(
    RecruitmentSource VARCHAR(100),
    FromDiversityJobFairID INT
);

CREATE TABLE silver.performance
(
    performance_id INT,
    performance_score VARCHAR(50)
);

CREATE TABLE silver.emp_status
(
    empstatus_id INT,
    emp_status VARCHAR(100),
    termreason VARCHAR(255),
    termd BIT
);

CREATE TABLE silver.hr_snapshot
(
    salary DECIMAL(18,2),
    absences INT,
    dayslatelast30 INT,
    engagementsurvey FLOAT,
    empsatisfaction INT,
    empstatus_id INT,
    specialprojectscount INT,
    date_hiring DATE,
    date_termination DATE,
    LastPerformanceReview_Date DATE,
    RecruitmentSource VARCHAR(100),
    position_id INT,
    manager_id INT,
    dept_id INT,
    performance_id INT,
    emp_id INT
);
GO

/*==========================
DML
==========================*/

INSERT INTO silver.emp
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
SELECT 
    TRY_CAST(TRIM(EmpID) AS INT),
    CASE
        WHEN CHARINDEX(',', Employee_Name) > 0 THEN
            UPPER(
                LTRIM(SUBSTRING(Employee_Name, CHARINDEX(',', Employee_Name) + 1, LEN(Employee_Name)))
                + ' ' +
                LTRIM(LEFT(Employee_Name, CHARINDEX(',', Employee_Name) - 1))
            )
        ELSE
            UPPER(TRIM(Employee_Name))
    END,
    UPPER(TRIM(Sex)),
    TRY_CONVERT(DATE, DOB),
    UPPER(TRIM(MaritalDesc)),
    UPPER(TRIM(CitizenDesc)),
    UPPER(TRIM(HispanicLatino)),
    UPPER(TRIM(RaceDesc)),
    UPPER(TRIM(State))
FROM bronze.hr_data;
GO

INSERT INTO silver.position
(
    position_id,
    position
)
SELECT
    TRY_CAST(TRIM(PositionID) AS INT),
    UPPER(TRIM(Position))
FROM bronze.hr_data
WHERE PositionID IS NOT NULL;
GO

INSERT INTO silver.manager
(
    manager_id,
    manager_name
)
SELECT
    TRY_CAST(TRIM(ManagerID) AS INT),
    UPPER(TRIM(ManagerName))
FROM bronze.hr_data
WHERE ManagerID IS NOT NULL;
GO

INSERT INTO silver.department
(
    dept_id,
    dept_name
)
SELECT
    TRY_CAST(TRIM(DeptID) AS INT),
    UPPER(TRIM(Department))
FROM bronze.hr_data
WHERE DeptID IS NOT NULL;
GO

INSERT INTO silver.recruitment
(
    RecruitmentSource,
    FromDiversityJobFairID
)
SELECT
    UPPER(TRIM(RecruitmentSource)),
    COALESCE(TRY_CAST(FromDiversityJobFairID AS INT),0)
FROM bronze.hr_data
WHERE RecruitmentSource IS NOT NULL;
GO

INSERT INTO silver.performance
(
    performance_id,
    performance_score
)
SELECT
    TRY_CAST(TRIM(PerfScoreID) AS INT),
    UPPER(TRIM(PerformanceScore))
FROM bronze.hr_data
WHERE PerfScoreID IS NOT NULL;
GO

INSERT INTO silver.emp_status
(
    empstatus_id,
    emp_status,
    termreason,
    termd
)
SELECT
    TRY_CAST(TRIM(EmpStatusID) AS INT),
    UPPER(TRIM(EmploymentStatus)),
    TRIM(TermReason),
    CAST(Termd AS INT)
FROM bronze.hr_data
WHERE EmpStatusID IS NOT NULL;
GO
/*==========================
DML - FACT_HR_snapshot
==========================*/

INSERT INTO silver.hr_snapshot
(
    salary,
    absences,
    dayslatelast30,
    engagementsurvey,
    empsatisfaction,
    specialprojectscount,
    empstatus_id,
    date_hiring,
    date_termination,
    LastPerformanceReview_Date,
    RecruitmentSource,
    position_id,
    manager_id,
    dept_id,
    performance_id,
    emp_id
)
SELECT
    COALESCE(TRY_CAST(Salary AS DECIMAL(18,2)),0),
    COALESCE(TRY_CAST(Absences AS INT),0),
    COALESCE(TRY_CAST(DaysLateLast30 AS INT),0),
    COALESCE(TRY_CAST(EngagementSurvey AS FLOAT),0),
    COALESCE(TRY_CAST(EmpSatisfaction AS INT),0),
    COALESCE(TRY_CAST(SpecialProjectsCount AS INT),0),
    TRY_CAST(TRIM(EmpStatusID) AS INT),
    TRY_CONVERT(DATE, DateofHire),
    TRY_CONVERT(DATE, DateofTermination),
    TRY_CONVERT(DATE, LastPerformanceReview_Date),
    UPPER(TRIM(RecruitmentSource)),
    TRY_CAST(TRIM(PositionID) AS INT),
    TRY_CAST(TRIM(ManagerID) AS INT),
    TRY_CAST(TRIM(DeptID) AS INT),
    TRY_CAST(TRIM(PerfScoreID) AS INT),
    TRY_CAST(TRIM(EmpID) AS INT)
FROM bronze.hr_data;
GO