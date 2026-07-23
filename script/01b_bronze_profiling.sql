USE HR_Project;
GO

/*=========================================================
1. Duplicate EmpID
=========================================================*/
SELECT
    'hr_data' AS [Table],
    'Duplicate Employee IDs' AS [Anomaly_Type],
    COUNT(*) AS [Affected_Row_Count],
    STUFF((
        SELECT DISTINCT ', ' + TRIM(EmpID)
        FROM bronze.hr_data
        GROUP BY EmpID
        HAVING COUNT(*) > 1
        FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,'') AS [Duplicate_Keys]
FROM (
    SELECT EmpID
    FROM bronze.hr_data
    GROUP BY EmpID
    HAVING COUNT(*)>1
) D;
GO

/*=========================================================
2. Missing Employee Name
=========================================================*/
SELECT
'hr_data' AS [Table],
'Missing Employee Name' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Employee_Name IS NULL
OR TRIM(Employee_Name)='';
GO

/*=========================================================
3. Missing Department
=========================================================*/
SELECT
'hr_data' AS [Table],
'Missing Department' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Department IS NULL
OR TRIM(Department)='';
GO

/*=========================================================
4. Missing Position
=========================================================*/
SELECT
'hr_data' AS [Table],
'Missing Position' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE Position IS NULL
OR TRIM(Position)='';
GO

/*=========================================================
5. Missing ManagerID
=========================================================*/
SELECT
'hr_data' AS [Table],
'Missing ManagerID' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE ManagerID IS NULL
OR TRIM(ManagerID)='';
GO

/*=========================================================
6. Invalid Salary
=========================================================*/
SELECT
'hr_data' AS [Table],
'Invalid Salary (<=0)' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(Salary AS FLOAT)<=0;
GO

/*=========================================================
7. Invalid Engagement Survey
=========================================================*/
SELECT
'hr_data' AS [Table],
'Invalid Engagement Survey' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(EngagementSurvey AS FLOAT) NOT BETWEEN 0 AND 5;
GO

/*=========================================================
8. Invalid Employee Satisfaction
=========================================================*/
SELECT
'hr_data' AS [Table],
'Invalid Employee Satisfaction' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(EmpSatisfaction AS INT) NOT BETWEEN 1 AND 5;
GO

/*=========================================================
9. Invalid Absences
=========================================================*/
SELECT
'hr_data' AS [Table],
'Negative Absences' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(Absences AS INT)<0;
GO

/*=========================================================
10. Invalid Days Late
=========================================================*/
SELECT
'hr_data' AS [Table],
'Negative Days Late' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CAST(DaysLateLast30 AS INT)<0;
GO

/*=========================================================
11. Duplicate Employee Names
=========================================================*/
SELECT
'hr_data' AS [Table],
'Duplicate Employee Names' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count],
STUFF((
SELECT DISTINCT ', '+Employee_Name
FROM bronze.hr_data
GROUP BY Employee_Name
HAVING COUNT(*)>1
FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,'') AS [Duplicate_Names]
FROM(
SELECT Employee_Name
FROM bronze.hr_data
GROUP BY Employee_Name
HAVING COUNT(*)>1
)X;
GO

/*=========================================================
12. Invalid ManagerID (Orphan Records)
=========================================================*/
SELECT
'hr_data' AS [Table],
'Orphan Manager IDs' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count],
STUFF((
SELECT DISTINCT ', '+TRIM(e2.ManagerID)
FROM bronze.hr_data e2
LEFT JOIN bronze.hr_data m
ON TRY_CAST(e2.ManagerID AS INT)=TRY_CAST(m.EmpID AS INT)
WHERE e2.ManagerID IS NOT NULL
AND TRIM(e2.ManagerID)<>''
AND m.EmpID IS NULL
FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,2,'') AS [Missing_ManagerIDs]
FROM bronze.hr_data e
LEFT JOIN bronze.hr_data m
ON TRY_CAST(e.ManagerID AS INT)=TRY_CAST(m.EmpID AS INT)
WHERE e.ManagerID IS NOT NULL
AND TRIM(e.ManagerID)<>''
AND m.EmpID IS NULL;
GO

/*=========================================================
13. Invalid Hire Date
=========================================================*/
SELECT
'hr_data' AS [Table],
'Invalid Hire Date' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE TRY_CONVERT(date,DateofHire) IS NULL;
GO

/*=========================================================
14. Invalid Termination Date
=========================================================*/
SELECT
'hr_data' AS [Table],
'Invalid Termination Date' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE DateofTermination IS NOT NULL
AND TRIM(DateofTermination)<>''
AND TRY_CONVERT(date,DateofTermination) IS NULL;
GO

/*=========================================================
15. Missing Performance Score
=========================================================*/
SELECT
'hr_data' AS [Table],
'Missing Performance Score' AS [Anomaly_Type],
COUNT(*) AS [Affected_Row_Count]
FROM bronze.hr_data
WHERE PerformanceScore IS NULL
OR TRIM(PerformanceScore)='';
GO