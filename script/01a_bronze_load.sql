USE HR_Project;  
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
FROM 'C:\Users\pc\Documents\GitHub\HR-DataWarehouse-Project\HR-DataWarehouse-Project\data\HRDataset_v14.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',   
    CODEPAGE = '65001',         
    TABLOCK
);
GO

SELECT COUNT(*) AS row_count FROM bronze.hr_data;


SELECT COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze' AND TABLE_NAME = 'hr_data';