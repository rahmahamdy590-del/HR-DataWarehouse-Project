USE HR_Project;
GO

SELECT 'Total Rows' AS Metric_Name, COUNT(*) AS Metric_Value 
FROM bronze.hr_data;
GO

SELECT TOP 100 * 
FROM bronze.hr_data;
GO
SELECT 
    EmpID, 
    COUNT(*) AS Occurrence_Count
FROM bronze.hr_data
GROUP BY EmpID
HAVING COUNT(*) > 1;
GO
SELECT 
    SUM(CASE WHEN EmpID IS NULL THEN 1 ELSE 0 END) AS Null_EmpID,
    SUM(CASE WHEN Employee_Name IS NULL THEN 1 ELSE 0 END) AS Null_Name,
    SUM(CASE WHEN ManagerID IS NULL THEN 1 ELSE 0 END) AS Null_ManagerID,
    SUM(CASE WHEN [DateofTermination] IS NULL THEN 1 ELSE 0 END) AS Null_TerminationDate,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS Null_Department
FROM bronze.hr_data;
GO

SELECT 
    MIN(Salary) AS Min_Salary,
    MAX(Salary) AS Max_Salary,
    ROUND(AVG(CAST(Salary AS FLOAT)), 2) AS Avg_Salary,
    MIN(EmpSatisfaction) AS Min_Satisfaction,
    MAX(EmpSatisfaction) AS Max_Satisfaction,
    MAX(Absences) AS Max_Absences
FROM bronze.hr_data;
GO

SELECT 
    Department, 
    COUNT(*) AS Employee_Count
FROM bronze.hr_data
GROUP BY Department
ORDER BY Employee_Count DESC;
GO

SELECT 
    EmploymentStatus, 
    COUNT(*) AS Employee_Count
FROM bronze.hr_data
GROUP BY EmploymentStatus
ORDER BY Employee_Count DESC;
GO

SELECT 
    PerformanceScore, 
    COUNT(*) AS Employee_Count
FROM bronze.hr_data
GROUP BY PerformanceScore
ORDER BY Employee_Count DESC;
GO