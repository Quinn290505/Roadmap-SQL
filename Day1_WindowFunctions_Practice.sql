/* ===============================================================================
DAY 1: ADVANCED SQL - MASTERING WINDOW FUNCTIONS
Topic: Aggregate, Ranking, Analytic, and Window Frames (ROWS & RANGE)
Data Source: Employee Demographics & Salary Dataset
===============================================================================
*/

-- 1. AGGREGATE WINDOW FUNCTIONS
-- Difference between GROUP BY and WINDOW FUNCTION
-- GROUP BY collapses rows, while WINDOW FUNCTION maintains individual row details.

-- Approach A: Aggregation using GROUP BY (Collapses details)
SELECT gender, AVG(salary) as avg_salary
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id
GROUP BY gender;

-- Approach B: Aggregation using WINDOW FUNCTION (Retains all rows)
SELECT 
    dem.first_name, 
    dem.last_name, 
    gender, 
    AVG(salary) OVER(PARTITION BY gender) AS avg_salary_by_gender
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id;


-- 2.1 SCOPE & PARTITIONING (OVER & PARTITION BY)
-- Requirement: Compare individual performance against company and department metrics.

SELECT 
    dem.first_name, 
    dem.last_name, 
    pd.department_name, 
    salary,
    -- Case: Relative to company average
    AVG(salary) OVER() AS company_avg_salary,
    salary - AVG(salary) OVER() AS salary_diff_from_company,
    -- Case: Relative to department average
    AVG(salary) OVER(PARTITION BY pd.department_name) AS dept_avg_salary,
    salary - AVG(salary) OVER(PARTITION BY pd.department_name) AS salary_diff_from_dept
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id
INNER JOIN parks_departments pd ON sal.dept_id = pd.department_id;

-- 2.2 ORDER BY( Cumulative/sequence)
SELECT dem.first_name, dem.last_name, gender, pd.department_name, salary,
SUM(salary) OVER( PARTITION BY pd.department_id
  ORDER BY salary DESC, dem.employee_id) AS ROLLING_TOTAL_IN_DEPT
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal
 ON dem.employee_id = sal.employee_id
INNER JOIN parks_departments pd
 ON sal.dept_id = pd.department_id
;    



-- 3. RANKING FUNCTIONS
-- Requirement: Rank employees by salary within each gender group.

SELECT 
    dem.employee_id, 
    dem.first_name, 
    salary,
    ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_num, -- Unique sequence
    RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rank_num,       -- Skips ranks on ties
    DENSE_RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS dense_rank_num -- Continuous ranks
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id;


-- 4. ANALYTIC FUNCTIONS (LEAD & LAG)
-- Purpose: Access data from preceding (LAG) or succeeding (LEAD) rows without self-joins.

SELECT 
    dem.first_name, 
    pd.department_name, 
    salary,
    -- Compare with the previous employee's salary in the same department
    LAG(salary, 1, 0) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) AS prev_salary,
    salary - LAG(salary, 1, 0) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) AS diff_from_prev,
    -- Compare with the next employee's salary
    LEAD(salary, 1, 0) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) AS next_salary
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id
JOIN parks_departments pd ON sal.dept_id = pd.department_id;


-- 5. VALUE FUNCTIONS (FIRST_VALUE & LAST_VALUE)
-- Note: LAST_VALUE requires proper Window Frame definition to look beyond the current row.

SELECT 
    dem.first_name, 
    pd.department_name, 
    salary,
    -- Highest salary in department
    FIRST_VALUE(salary) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) AS top_dept_salary,
    -- Lowest salary in department (Frame must be specified)
    LAST_VALUE(salary) OVER(
        PARTITION BY pd.department_id 
        ORDER BY salary DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_dept_salary,
    -- Practical Application: Gap Analysis
    salary / FIRST_VALUE(salary) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) AS ratio_to_top,
    FIRST_VALUE(salary) OVER(PARTITION BY pd.department_id ORDER BY salary DESC) - 
    LAST_VALUE(salary) OVER(PARTITION BY pd.department_id ORDER BY salary DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS salary_range_in_dept
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id
JOIN parks_departments pd ON sal.dept_id = pd.department_id;


-- 6. WINDOW FRAMES (ROWS VS. RANGE)
-- Master the precision of window boundaries.

-- A. ROWS: Physical row count (Rolling 3 rows sum)
SELECT first_name, salary,
    SUM(salary) OVER (ORDER BY salary ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_rows
FROM employee_salary;

-- B. RANGE: Data value proximity (Summing based on value difference)
SELECT first_name, salary,
    SUM(salary) OVER (ORDER BY salary RANGE BETWEEN 2000 PRECEDING AND CURRENT ROW) AS value_range_sum
FROM employee_salary;

-- C. RANGE INTERVAL: Time-based windows (Rolling 7-day period)
-- Note: Practiced on birth_date for syntax mastery; typically used on transaction dates.
SELECT 
    dem.first_name,
    dem.birth_date, 
    sal.salary, 
    SUM(sal.salary) OVER( 
        ORDER BY dem.birth_date  
        RANGE BETWEEN INTERVAL 7 DAY PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_salary
FROM employee_demographics AS dem
JOIN employee_salary AS sal ON dem.employee_id = sal.employee_id
ORDER BY dem.birth_date;
