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
-----------------DDL
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
    engagementsurvey DECIMAL(5,2),
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
-------------------DML
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
SELECT DISTINCT
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
    MAX(UPPER(TRIM(Position)))
FROM bronze.hr_data
WHERE TRY_CAST(TRIM(PositionID) AS INT) IS NOT NULL
GROUP BY TRY_CAST(TRIM(PositionID) AS INT);
GO
INSERT INTO silver.manager
(
    manager_id,
    manager_name
)
SELECT
    TRY_CAST(TRY_CAST(TRIM(ManagerID) AS FLOAT) AS INT),
    MAX(UPPER(TRIM(ManagerName)))
FROM bronze.hr_data
WHERE TRY_CAST(TRY_CAST(TRIM(ManagerID) AS FLOAT) AS INT) IS NOT NULL
GROUP BY TRY_CAST(TRY_CAST(TRIM(ManagerID) AS FLOAT) AS INT);
GO
INSERT INTO silver.department
(
    dept_id,
    dept_name
)
SELECT
    TRY_CAST(TRIM(DeptID) AS INT),
    MAX(UPPER(TRIM(Department)))
FROM bronze.hr_data
WHERE TRY_CAST(TRIM(DeptID) AS INT) IS NOT NULL
GROUP BY TRY_CAST(TRIM(DeptID) AS INT);
GO

INSERT INTO silver.recruitment
(
    RecruitmentSource,
    FromDiversityJobFairID
)
SELECT
    UPPER(TRIM(RecruitmentSource)),
    MAX(COALESCE(TRY_CAST(FromDiversityJobFairID AS INT),0))
FROM bronze.hr_data
WHERE RecruitmentSource IS NOT NULL
AND TRIM(RecruitmentSource)<>''
GROUP BY UPPER(TRIM(RecruitmentSource));
GO

INSERT INTO silver.performance
(
    performance_id,
    performance_score
)
SELECT
    TRY_CAST(TRIM(PerfScoreID) AS INT),
    MAX(UPPER(TRIM(PerformanceScore)))
FROM bronze.hr_data
WHERE TRY_CAST(TRIM(PerfScoreID) AS INT) IS NOT NULL
GROUP BY TRY_CAST(TRIM(PerfScoreID) AS INT);
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
    MAX(UPPER(TRIM(EmploymentStatus))),
    MAX(TRIM(TermReason)),
    CAST(MAX(CAST(Termd AS INT)) AS BIT)
FROM bronze.hr_data
WHERE TRY_CAST(TRIM(EmpStatusID) AS INT) IS NOT NULL
GROUP BY TRY_CAST(TRIM(EmpStatusID) AS INT);
GO
---------------------DML - HR_snapshot
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
    COALESCE(TRY_CAST(EngagementSurvey AS DECIMAL(5,2)),0),
    COALESCE(TRY_CAST(EmpSatisfaction AS INT),0),
    COALESCE(TRY_CAST(SpecialProjectsCount AS INT),0),
    TRY_CAST(TRIM(EmpStatusID) AS INT),
    TRY_CONVERT(DATE, DateofHire),
    TRY_CONVERT(DATE, DateofTermination),
    TRY_CONVERT(DATE, LastPerformanceReview_Date),
    CASE
         WHEN RecruitmentSource IS NULL
             OR TRIM(RecruitmentSource)='' THEN 'UNKNOWN'
         ELSE UPPER(TRIM(RecruitmentSource))
    END,
    TRY_CAST(TRIM(PositionID) AS INT),
    TRY_CAST(TRY_CAST(TRIM(ManagerID) AS FLOAT) AS INT),
    TRY_CAST(TRIM(DeptID) AS INT),
    TRY_CAST(TRIM(PerfScoreID) AS INT),
    TRY_CAST(TRIM(EmpID) AS INT)
FROM bronze.hr_data;
GO
