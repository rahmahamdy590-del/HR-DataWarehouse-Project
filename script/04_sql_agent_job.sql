USE [msdb]
GO

/****** Object:  Job [HR ETL Pipeline]    Script Date: 7/25/2026 8:58:08 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/25/2026 8:58:08 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'HR ETL Pipeline', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [00_Initialize]    Script Date: 7/25/2026 8:58:09 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'00_Initialize', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF DB_ID(''HR_Project'') IS NULL
BEGIN
    CREATE DATABASE HR_Project;
END
GO

USE HR_Project;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''bronze'')
    EXEC(''CREATE SCHEMA bronze'');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''silver'')
    EXEC(''CREATE SCHEMA silver'');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''gold'')
    EXEC(''CREATE SCHEMA gold'');
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [01a_Bronze_Load]    Script Date: 7/25/2026 8:58:09 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'01a_Bronze_Load', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE HR_Project;  
GO

DROP TABLE IF EXISTS bronze.hr_data;
GO

CREATE TABLE bronze.hr_data (
    Employee_Name               VARCHAR(MAX),
    EmpID                       VARCHAR(MAX),
    MarriedID                   VARCHAR(MAX),
    MaritalStatusID             VARCHAR(MAX),
    GenderID                    VARCHAR(MAX),
    EmpStatusID                 VARCHAR(MAX),
    DeptID                      VARCHAR(MAX),
    PerfScoreID                 VARCHAR(MAX),
    FromDiversityJobFairID      VARCHAR(MAX),
    Salary                      VARCHAR(MAX),
    Termd                       VARCHAR(MAX),
    PositionID                  VARCHAR(MAX),
    Position                    VARCHAR(MAX),
    State                       VARCHAR(MAX),
    Zip                         VARCHAR(MAX),
    DOB                         VARCHAR(MAX),
    Sex                         VARCHAR(MAX),
    MaritalDesc                 VARCHAR(MAX),
    CitizenDesc                 VARCHAR(MAX),
    HispanicLatino              VARCHAR(MAX),
    RaceDesc                    VARCHAR(MAX),
    DateofHire                  VARCHAR(MAX),
    DateofTermination           VARCHAR(MAX),
    TermReason                  VARCHAR(MAX),
    EmploymentStatus            VARCHAR(MAX),
    Department                  VARCHAR(MAX),
    ManagerName                 VARCHAR(MAX),
    ManagerID                   VARCHAR(MAX),
    RecruitmentSource           VARCHAR(MAX),
    PerformanceScore            VARCHAR(MAX),
    EngagementSurvey            VARCHAR(MAX),
    EmpSatisfaction             VARCHAR(MAX),
    SpecialProjectsCount        VARCHAR(MAX),
    LastPerformanceReview_Date  VARCHAR(MAX),
    DaysLateLast30              VARCHAR(MAX),
    Absences                    VARCHAR(MAX)
);
GO

BULK INSERT bronze.hr_data
FROM ''C:\Users\pc\Documents\GitHub\HR-DataWarehouse-Project\HR-DataWarehouse-Project\data\HRDataset_v14.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDQUOTE = ''"'',
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''0x0d0a'',   
    CODEPAGE = ''65001'',         
    TABLOCK
);
GO

SELECT COUNT(*) AS row_count FROM bronze.hr_data;


SELECT COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = ''bronze'' AND TABLE_NAME = ''hr_data'';', 
		@database_name=N'HR_Project', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [01b_Bronze_Profiling]    Script Date: 7/25/2026 8:58:09 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'01b_Bronze_Profiling', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE HR_Project;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/*=========================================================
1. Duplicate EmpID
=========================================================*/
SELECT
    ''hr_data'' AS [Table],
    ''Duplicate Employee IDs'' AS [Anomaly_Type],
    COUNT(*) AS [Affected_Row_Count],
    STUFF((
        SELECT DISTINCT '', '' + TRIM(EmpID)
        FROM bronze.hr_data
        GROUP BY TRIM(EmpID)
        HAVING COUNT(*) > 1
        FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS [Duplicate_Keys]
FROM (
    SELECT TRIM(EmpID) AS EmpID
    FROM bronze.hr_data
    GROUP BY TRIM(EmpID)
    HAVING COUNT(*)>1
) D;
GO

/*=========================================================
2. Missing Employee Name
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Missing Employee Name'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Employee_Name IS NULL
OR TRIM(Employee_Name)='''';
GO

/*=========================================================
3. Missing Department
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Missing Department'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Department IS NULL
OR TRIM(Department)='''';
GO

/*=========================================================
4. Missing Position
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Missing Position'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Position IS NULL
OR TRIM(Position)='''';
GO

/*=========================================================
5. Missing ManagerID
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Missing ManagerID'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE ManagerID IS NULL
OR TRIM(ManagerID)='''';
GO

/*=========================================================
6. Invalid Salary
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Invalid Salary (<=0)'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(Salary AS FLOAT)<=0;
GO

/*=========================================================
7. Invalid Engagement Survey
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Invalid Engagement Survey'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(EngagementSurvey AS FLOAT) NOT BETWEEN 0 AND 5;
GO

/*=========================================================
8. Invalid Employee Satisfaction
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Invalid Employee Satisfaction'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(EmpSatisfaction AS INT) NOT BETWEEN 1 AND 5;
GO

/*=========================================================
9. Invalid Absences
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Negative Absences'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(Absences AS INT)<0;
GO

/*=========================================================
10. Invalid Days Late
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Negative Days Late'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(DaysLateLast30 AS INT)<0;
GO

/*=========================================================
11. Duplicate Employee Names
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Duplicate Employee Names'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count],
STUFF((
SELECT DISTINCT '', ''+Employee_Name
FROM bronze.hr_data
GROUP BY Employee_Name
HAVING COUNT(*)>1
FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS [Duplicate_Names]
FROM(
SELECT Employee_Name
FROM bronze.hr_data
GROUP BY Employee_Name
HAVING COUNT(*)>1
)X;
GO

/*=========================================================
12. Invalid ManagerID (Orphan Records)
-- FIX: ManagerID/EmpID may be stored as text with a decimal point
-- (e.g. "1.0"), which TRY_CAST(... AS INT) directly rejects and
-- returns NULL for. Casting ManagerID through FLOAT first, and
-- TRIM-ing EmpID before casting, keeps this join reliable.
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Orphan Manager IDs'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count],
STUFF((
SELECT DISTINCT '', ''+TRIM(e2.ManagerID)
FROM bronze.hr_data e2
LEFT JOIN bronze.hr_data m
ON TRY_CAST(TRY_CAST(e2.ManagerID AS FLOAT) AS INT) = TRY_CAST(TRIM(m.EmpID) AS INT)
WHERE e2.ManagerID IS NOT NULL
AND TRIM(e2.ManagerID)<>''''
AND m.EmpID IS NULL
FOR XML PATH(''''),TYPE).value(''.'',''NVARCHAR(MAX)''),1,2,'''') AS [Missing_ManagerIDs]
FROM bronze.hr_data e
LEFT JOIN bronze.hr_data m
ON TRY_CAST(TRY_CAST(e.ManagerID AS FLOAT) AS INT) = TRY_CAST(TRIM(m.EmpID) AS INT)
WHERE e.ManagerID IS NOT NULL
AND TRIM(e.ManagerID)<>''''
AND m.EmpID IS NULL;
GO

/*=========================================================
13. Invalid Hire Date
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Invalid Hire Date'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CONVERT(date,DateofHire) IS NULL;
GO

/*=========================================================
14. Invalid Termination Date
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Invalid Termination Date'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE DateofTermination IS NOT NULL
AND TRIM(DateofTermination)<>''''
AND TRY_CONVERT(date,DateofTermination) IS NULL;
GO

/*=========================================================
15. Missing Performance Score
=========================================================*/
SELECT
''hr_data'' AS [Table],
''Missing Performance Score'' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE PerformanceScore IS NULL
OR TRIM(PerformanceScore)='''';
GO', 
		@database_name=N'HR_Project', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [02_Silver]    Script Date: 7/25/2026 8:58:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'02_Silver', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE HR_Project;
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
        WHEN CHARINDEX('','', Employee_Name) > 0 THEN
            UPPER(
                LTRIM(SUBSTRING(Employee_Name, CHARINDEX('','', Employee_Name) + 1, LEN(Employee_Name)))
                + '' '' +
                LTRIM(LEFT(Employee_Name, CHARINDEX('','', Employee_Name) - 1))
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
    CASE
        WHEN RecruitmentSource IS NULL OR TRIM(RecruitmentSource)='''' THEN ''UNKNOWN''
        ELSE UPPER(TRIM(RecruitmentSource))
    END,
    MAX(COALESCE(TRY_CAST(FromDiversityJobFairID AS INT),0))
FROM bronze.hr_data
GROUP BY 
    CASE
        WHEN RecruitmentSource IS NULL OR TRIM(RecruitmentSource)='''' THEN ''UNKNOWN''
        ELSE UPPER(TRIM(RecruitmentSource))
    END;
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
             OR TRIM(RecruitmentSource)='''' THEN ''UNKNOWN''
         ELSE UPPER(TRIM(RecruitmentSource))
    END,
    TRY_CAST(TRIM(PositionID) AS INT),
    TRY_CAST(TRY_CAST(TRIM(ManagerID) AS FLOAT) AS INT),
    TRY_CAST(TRIM(DeptID) AS INT),
    TRY_CAST(TRIM(PerfScoreID) AS INT),
    TRY_CAST(TRIM(EmpID) AS INT)
FROM bronze.hr_data;
GO
', 
		@database_name=N'HR_Project', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [03_Gold]    Script Date: 7/25/2026 8:58:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'03_Gold', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE HR_Project;
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
-----------DDL - DIMENSIONS (surrogate key = sk_<dimension>, NOT NULL by definition of IDENTITY PK; business key = UNIQUE, so no duplicate surrogate rows for the same source key)
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
-------DML - FACT_HR_SNAPSHOT (look up each dimension''s surrogate key via its business key)
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
''Silver HR Snapshot'' AS Layer,
COUNT(*) AS Row_Count
FROM silver.hr_snapshot
UNION ALL
SELECT
''Gold Fact HR Snapshot'',
COUNT(*)
FROM gold.fact_hr_snapshot;
GO

-- Rows in the fact table missing any surrogate key
SELECT * FROM gold.fact_hr_snapshot
WHERE sk_emp IS NULL OR sk_position IS NULL OR sk_department IS NULL
   OR sk_manager IS NULL OR sk_performance IS NULL OR sk_emp_status IS NULL
   OR sk_recruitment IS NULL;
GO

-- Drill down: raw bronze rows behind any sk_manager gaps found above
-- (dynamic - no hardcoded IDs, re-runs correctly on any future load)
SELECT b.EmpID, b.Employee_Name, b.ManagerID, b.ManagerName, b.Position
FROM bronze.hr_data b
WHERE TRY_CAST(TRIM(b.EmpID) AS INT) IN (
    SELECT de.emp_id
    FROM gold.fact_hr_snapshot f
    JOIN gold.dim_emp de ON de.sk_emp = f.sk_emp
    WHERE f.sk_manager IS NULL
);
GO
------------check for null
SELECT
    emp_id,
    manager_id
FROM silver.hr_snapshot
WHERE emp_id IN
(
    10277,
    10184,
    10154,
    10136,
    10214,
    10077,
    10011,
    10071
);
SELECT *
FROM silver.manager
WHERE manager_name = ''WEBSTER BUTLER'';

SELECT
    EmpID,
    ManagerID,
    ManagerName
FROM bronze.hr_data
WHERE ManagerName = ''Webster Butler'';', 
		@database_name=N'HR_Project', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily ETL', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20260725, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'94ca6bf7-e69c-47ba-89a7-c4f75a32c450'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


