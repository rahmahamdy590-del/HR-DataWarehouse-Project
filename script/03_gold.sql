USE HR_Project;
GO
DROP VIEW IF EXISTS gold.v_fact_hr_snapshot;
DROP VIEW IF EXISTS gold.v_dim_employee;
DROP VIEW IF EXISTS gold.v_dim_position;
DROP VIEW IF EXISTS gold.v_dim_manager;
DROP VIEW IF EXISTS gold.v_dim_performance;
DROP VIEW IF EXISTS gold.v_dim_recruitment;
GO
-----------DDL -
CREATE VIEW gold.v_dim_employee AS
SELECT
      e.emp_id, 
      e.emp_name, 
      e.sex,
      e.dob,
      e.marital_desc,
      e.citizen_desc,
      e.hispanic_latino,
      e.race_desc,
      e.state,
      es.empstatus_id, 
      es.emp_status, 
      es.termreason,
      es.termd
FROM silver.emp e LEFT JOIN silver.emp_status es ON e.empstatus_id = es.empstatus_id;
GO

CREATE VIEW gold.v_dim_position AS
SELECT
    p.position_id,
    p.position,
    d.dept_id,
    d.dept_name
FROM silver.position p LEFT JOIN silver.department d ON p.dept_id = d.dept_id;
GO

CREATE VIEW gold.v_dim_manager AS
SELECT
      m.manager_id,
      m.manager_name
FROM silver.manager m;
GO

CREATE VIEW gold.v_dim_performance AS
SELECT
     pr.performance_id,
     pr.performance_score
FROM silver.performance pr;
GO

CREATE VIEW gold.v_dim_recruitment AS
SELECT
     r.RecruitmentSource,
     r.FromDiversityJobFairID
FROM silver.recruitment r;
GO

--------DDL 
CREATE VIEW gold.v_fact_hr_snapshot AS
SELECT
    e.emp_id,
    e.emp_name,
    p.position_id,
    p.position,
    p.dept_id,
    p.dept_name,
    m.manager_id,
    m.manager_name,
    pr.performance_id,
    pr.performance_score,
    r.RecruitmentSource,
    r.FromDiversityJobFairID,
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
LEFT JOIN gold.v_dim_employee e ON s.emp_id = e.emp_id
LEFT JOIN gold.v_dim_position p ON s.position_id = p.position_id
LEFT JOIN gold.v_dim_manager m ON s.manager_id = m.manager_id
LEFT JOIN gold.v_dim_performance pr ON s.performance_id = pr.performance_id
LEFT JOIN gold.v_dim_recruitment r ON s.RecruitmentSource = r.RecruitmentSource
GO 

-------------------------------VALIDATION
-----1)
SELECT COUNT(*) AS Silver_Count
FROM silver.hr_snapshot;
SELECT COUNT(*) AS Gold_Count
FROM gold.v_fact_hr_snapshot;
-----2)
SELECT *
FROM gold.v_fact_hr_snapshot f
LEFT JOIN gold.v_dim_employee e
ON f.emp_id = e.emp_id
WHERE e.emp_id IS NULL;
-----3)
SELECT *
FROM gold.v_fact_hr_snapshot f
LEFT JOIN gold.v_dim_position p
ON f.position_id = p.position_id
WHERE p.position_id IS NULL;
-----4)
SELECT
    EmpStatusID,
    COUNT(DISTINCT EmploymentStatus) AS Different_Statuses
FROM bronze.hr_data
GROUP BY EmpStatusID
HAVING COUNT(DISTINCT EmploymentStatus) > 1;
-----5)
SELECT
    e.emp_name,
    es.emp_status,
    h.date_termination
FROM silver.hr_snapshot h
JOIN silver.emp e
ON h.emp_id = e.emp_id
JOIN silver.emp_status es
ON e.empstatus_id = es.empstatus_id
WHERE es.emp_status <> 'ACTIVE'
AND h.date_termination IS NULL;
