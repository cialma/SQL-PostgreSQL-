-- SQL / PostgreSQL HR Database & Analytics
-- Author: Ekaterina Filimonova
-- Portfolio project
-- Demonstrates:
-- relational database design
-- primary / foreign keys and ENUM types
-- analytical SQL queries and aggregations
-- JOINs, subqueries, VIEWs and CTEs
-- date / range operations
-- PL/pgSQL functions and exception handling
-- window functions (LAG, LEAD, DENSE_RANK, NTILE)


SET search_path TO staff;
-- 1. DATABASE SCHEMA

CREATE TYPE bonus_names_types AS ENUM
    ('basic', 'intermediate', 'advanced');


-- Create 'department' table
CREATE TABLE department
(
    dep_id smallserial NOT NULL,
    dep_name text NOT NULL,
    address text,
    CONSTRAINT department_pkey PRIMARY KEY (dep_id)
);

-- Create 'position' table
CREATE TABLE position
(
    pos_id smallserial NOT NULL,
    pos_title text NOT NULL,
	base_salary numeric(9,2),
	dep_id smallint,
	CONSTRAINT position_pkey PRIMARY KEY (pos_id),
	CONSTRAINT pos_dep_fkey FOREIGN KEY (dep_id)
        REFERENCES department (dep_id)
);

-- Create 'employee' table
CREATE TABLE employee
(
    emp_id serial NOT NULL,
	name text NOT NULL,
	birth_date date,
	passport_num text,
	phone text,
    pos_id smallint NOT NULL,
    CONSTRAINT employee_pkey PRIMARY KEY (emp_id),
    CONSTRAINT employee_pos_fkey FOREIGN KEY (pos_id)
        REFERENCES position (pos_id)
);

-- Create 'bonus_type' table
CREATE TABLE bonus_type
(
    bonus_id smallserial NOT NULL,
	bonus_name bonus_names_types NOT NULL,
	salary_share numeric(5,2),
    CONSTRAINT bonus_type_pkey PRIMARY KEY (bonus_id)
);

-- Create a table, linking employees and their bonuses
CREATE TABLE emp_bonus
(
    emp_bonus_id serial NOT NULL,
    startdate date NOT NULL,
    end_date date,
    bonus_id smallint NOT NULL,
    emp_id int NOT NULL,
    CONSTRAINT emp_bonus_pkey PRIMARY KEY (emp_bonus_id),
    CONSTRAINT emp_bonus_emp_fkey FOREIGN KEY (emp_id)
        REFERENCES employee (emp_id),
    CONSTRAINT emp_bonus_type_fkey FOREIGN KEY (bonus_id)
        REFERENCES bonus_type (bonus_id)
);
SET search_path TO staff;

-- 2. SAMPLE DATA

INSERT INTO department(
	dep_name, address)
	VALUES
	('Marketing Department', 'Kantemirovskaya street, 3'),
	('HR Department', 'Nevsky Prospekt, 64'),
	('Information Security Department', 'Sedova street, 55'),
	('Accounting Department', 'Kantemirovskaya street, 3'),
	('Programming Department', 'Stachek Avenue, 21'),
	('Testing Department', 'Stachek Avenue, 21');

INSERT INTO position(
	pos_title, base_salary, dep_id)
	VALUES
	('Head of Marketing Department', 200000, 1),
	('Marketing Analyst', 120000, 1),
	('HRD', 190000, 2),
	('Lead Specialist of the HR Department', 150000, 2),
	('System Administrator', 130000, 3),
	('Accountant', 120000, 4),
	('Lead Developer', 210000, 5),
	('Senior Developer', 150000, 5),
	('QA Specialist', 140000, null);


INSERT INTO employee(
	name, birth_date, passport_num, phone, pos_id)
	VALUES
	('Ivan Venediktov',     make_date(1983,11,2), '5727 152725', '+7(912)842-48-25', 1),
	('Oleg Vasiliev', 	make_date(1988,3,25), '4457 982645', '+7(912)948-64-79', 2),
	('Anna Melnikova', 	make_date(1995,5,19), '8722 047574', '+7(951)725-20-25', 3),
	('Stepan Ignatov', 	make_date(1991,5,8), '8746 161161', '+7(922)542-04-27', 4),
	('Daria Nikitina', 	make_date(1999,8,12), '2516 489914', '+7(922)454-72-53', 5),
	('Alexander Becker', 	make_date(1985,12,16), '5821 454815', '+7(922)154-17-52', 6),
	('Dmitry Belov', 	make_date(1985,4,6), '7357 274204', '+7(951)544-68-66', 6),
	('Ksenia Frantz', 	make_date(1999,7,24), '7254 354549', '+7(951)124-46-13', 6),
	('Victor Pogudin', 	make_date(1993,11,29), '3778 454437', '+7(922)777-87-14', 7),
	('Valeria Morozova', 	make_date(1991,9,1), '4544 353775', '+7(912)735-24-33', 8),
	('Sofia Besedina', 	make_date(1987,9,22), '8345 044578', '+7(912)454-07-11', 9);

-- 3. BASIC ANALYTICAL QUERIES

SELECT * FROM department;

--3 Transfer Alexander Becker to the position of “Lead Developer” using the UPDATE query.--
UPDATE employee
SET pos_id = 7
WHERE name = 'Alexander Becker';

-- 4 Use the SELECT query to display a list of the names of all departments of the company.

SELECT dep_name
FROM department

-- Display the number of all departments in the company.

SELECT count(dep_name) as "Number of departments"
FROM department

--Display a list of positions with salaries above 150,000 ₽.
SELECT pos_title , base_salary
FROM position
WHERE base_salary > 150000;

-- Display the names of the departments and the number of positions in each of them. Leave only those
--departments with more than 1 position.
SELECT dep_name, count(pos_id)
FROM department d
LEFT JOIN position p on d.dep_id = p.dep_id
GROUP BY dep_name
HAVING count(pos_id)>1
ORDER BY count (pos_id) desc

-- 8 Increase the salary for the position of “Lead Developer” by 10%.
UPDATE position
SET base_salary = base_salary * 1.10
WHERE pos_title = 'Lead Developer'

--9 Display a list of unique addresses of company departments (i.e. each address should be displayed only 1 time).
SELECT address
FROM department
GROUP BY address;

-- 10 Print the number of addresses where the company's departments are located.
SELECT count (address) as "Number of addresses where the company's departments are located."
FROM department
GROUP BY address;

--11 Output the average salary of positions for the company.
SELECT avg(base_salary) as average_salary
FROM position

--12 Output the average salary of real employees for each department.
SELECT dep_name as "Department name" , AVG(base_salary) as "Average salary"
FROM position p
JOIN department d on p.dep_id = d.dep_id
GROUP BY d.dep_id ;

--13 Output the average salary of real employees in the “Programming Department”.
SELECT AVG(base_salary) as "Average salary"
FROM position p
JOIN department d on p.dep_id = d.dep_id
WHERE dep_name = 'Programming Department'

-- 14 Add information about the types of bonuses:basic – 5%;intermediate – 10%;advanced – 20%.Please note that the percentage of salary is stored as a real number.
INSERT INTO bonus_type(bonus_name, salary_share) values ('basic', 5.0), ('intermediate', 10.0), ('advanced', 20.0)

--Assign bonuses to the following employees:Ksenia Frantz – basic;Anna Melnikova – intermediate;Alexander Becker – advanced.For Alexander Becker, set the start date of the bonus to the current date. For the other 2 employees, setany arbitrary suitable date. Leave the bonus expiration date blank for all 3 employees. insert into bonus_type(bonus_name, salary_share) values ('basic', 5.0), ('intermediate', 10.0), ('advanced', 20.0)
SELECT name
FROM employee
WHERE name = 'Ksenia Frantz'
OR name = 'Anna Melnikova'
OR name = 'Alexander Becker'

SELECT bonus_id,bonus_name , salary_share
FROM bonus_type
WHERE bonus_name in ('basic', 'intermediate','advanced')

INSERT INTO emp_bonus(emp_bonus_id, startdate, end_date, bonus_id, emp_id)
VALUES(101, '2026-01-01', NULL , 1, 8), (102, '2026-01-01', NULL, 2, 3) , (103, '2026-01-01', NULL, 3, 6)

SELECT *
FROM employee e
FULL JOIN emp_bonus on e.emp_id = emp_bonus.emp_id
FULL JOIN bonus_type on bonus_type.bonus_id = emp_bonus.bonus_id

-- 4. DATE, RANGE & BUSINESS TRIP QUERIES

--1. Print the full name of the employees who were born between January 1, 1990 (inclusive) and January 1, 2000 (not inclusive) along with the date of birth (2 columns). Use mathematical operators. Pay attention to the data types.
SELECT name as "born between January 1, 1990 (inclusive) and January 1, 2000 (not inclusive)" , birth_date
FROM employee
WHERE birth_date between '1990-01-01'and '1999-12-31'


--2. Count how many employees have a surname ending in "ov".

SELECT count(name) as "empl with ending in ov"
FROM employee
WHERE name LIKE '%ov'


--3. Print the full names of employees whose names begin with the letter "S".

SELECT name as "Full names"
FROM employee
WHERE name LIKE '%S%'

--4. Print the full names of employees whose names begin with any letter other than "S" and "D".

SELECT name as "Full names"
FROM employee
WHERE name not like 'S%' and name not like 'D%'

--5. Print the average salary for actual employees in the programming and marketing departments along with the department name (2 columns).

SELECT dep_name as "Department", avg(base_salary) as "Average salary"
FROM employee e
JOIN position p on e.pos_id = p.pos_id
JOIN department d on p.dep_id = d.dep_id
WHERE dep_name = 'Programming Department' or dep_name = 'Marketing Department'
GROUP BY d.dep_id

--6. Use cross join to join table employee with itself. Display only rows, where column with names from “first” table employee are not equal to column with names from “second” table employee. (2 columns)Display the current year, month, and day (3 columns).

SELECT e1.name as employee_name, e2.name as other_employee_name
FROM employee e1
CROSS JOIN employee e2
WHERE e1.name <> e2.name

--7. Display the current year, month, and day (3 columns).

SELECT current_date
, extract(year from current_date) as year
, extract(month from current_date) as month
, extract(day from current_date) as day

--8. Enter the names of the employees, who has an age between 30 and 35 years (inclusive) for the current day and change data type of age to integer. Set the current day as a variable — you should use it in calculating age of emloyees (2 columns).

SELECT name
,extract(year from age(current_date, birth_date))::int as age
FROM employee
WHERE extract(year from age(current_date, birth_date))::int
between 30 and 35;

--9. Print the number of days that have passed from September 1, 2025 to the current day. Set the current day as a variable.

SELECT current_date - date '2025-09-01'as days_passed;

--10. Print the number of days that have passed from the beginning of the previous month to the current day. Set the current day as a variable, and find the previous month using the variable of the current day and the function.
SELECT current_date - (date_trunc('month', current_date)::date - interval '1 month')::date
       as days_passed;
-- 11. Create a table about business trips called b_trips in the database containing information about the employee, the business trip city, and the business trip period.

CREATE TABLE IF NOT EXISTS b_trips
(
	trip_id serial,
	emp_id int,
	place varchar(255),
	trip_period daterange,
	CONSTRAINT b_trip_pkey PRIMARY KEY (trip_id),
	CONSTRAINT b_trip_fkey FOREIGN KEY (emp_id)
		REFERENCES employee(emp_id)
)

--12. Insert the following data into this table:
INSERT INTO b_trips (emp_id,place,trip_period) values
(1, 'Moscow', '[2024-09-10,2024-09-15]'),
(3, 'Krasnodar', '[2024-11-01,)'),
(7, 'Moscow ', '[2024-10-02,2024-10-09]'),
(8, 'Novosibirsk', '[2024-10-09,2024-10-12]'),
(4, 'Perm', '[2024-09-30,2024-10-05]'),
(11, 'Moscow ', '[2024-10-02,2024-10-09]')

--13. Display information about the beginning and end of each business trip in separate columns.
SELECT
	trip_id,
	lower(trip_period) as trip_start,
    upper(trip_period) as trip_end
FROM b_trips

--14. Display the names of the employees who are currently on a business trip and the period of their stay on a business trip (2 columns).

SELECT e.name as "Full name",(current_date - lower(bt.trip_period)) as "Trip period"
FROM b_trips bt
JOIN employee e on bt.emp_id = e.emp_id
WHERE bt.trip_period @> current_date

--15. Take out the information of the employees who were on a business trip to Perm.

SELECT e.*
FROM employee e
JOIN b_trips bt on e.emp_id = bt.emp_id
WHERE bt.place = 'Perm';

--16. Output the number of employees sent on a business trip in each month (count by the date of the start of the business trip).

SELECT
extract(year from lower(trip_period)) as year,
extract(month from lower(trip_period)) as month,
count(emp_id) as emp_count
FROM b_trips
GROUP BY year,month
ORDER BY year,month

-- 5. VIEWS, CTEs & MULTI-TABLE ANALYTICS

--1.Display information about employees: full name, position, department name and salary.

SELECT
    e.name as full_name,
    p.pos_title as position,
    d.dep_name as department,
    p.base_salary as salary
FROM employee e
JOIN position p on e.pos_id = p.pos_id
JOIN department d on p.dep_id = d.dep_id;

--2.	Create a view based on the previous query.

CREATE VIEW v_employee_info as
SELECT
    e.name        as "Full name",
    p.pos_title   as "Position",
    d.dep_name    as "Department",
    p.base_salary as "Salary"
FROM employee e
JOIN position p on e.pos_id = p.pos_id
JOIN department d on p.dep_id = d.dep_id;

--3.Write the code for the CTE, return select * from <cte_name> as the main query. You will need CTE for the tasks below.

WITH employee_info as (
    SELECT
        e.name        as "Full name",
        p.pos_title   as "Position",
        d.dep_name    as "Department",
        p.base_salary as "Salary"
    FROM employee e
    JOIN position p on e.pos_id = p.pos_id
    JOIN department d on p.dep_id = d.dep_id
)
SELECT *
FROM employee_info;
--4.Using the CTE or the created view, print the names of employees working in the positions of “Marketing Analyst” or “QA Specialist”, and the departments in which they work (use “coalesce” function if necessary).
SELECT
    "Full name",
    coalesce("Department", 'No department') as "Department"
FROM v_employee_info
WHERE "Position" in ('Marketing Analyst', 'QA Specialist');

--5.Using the CTE or the created view, display information about the number of employees working in each department (excluding employees who are not assigned to any position). The request should return the names of departments and the number of employees in them. Sort the result in descending order (use “coalesce” function if necessary).
SELECT
    coalesce("Department", 'No department') as "Department",
    count("Full name") as employee_count
FROM v_employee_info
GROUP BY "Department"
HAVING count("Full name") > 0
ORDER BY employee_count desc;
--6.	Using the CTE or the created view, display information about employees whose salary is higher or equal to the average salary in the company. The query should return the employee's name, position, department, and salary.
SELECT
    "Full name",
    "Position",
    coalesce("Department", 'No department') as "Department",
    "Salary"
FROM v_employee_info
WHERE "Salary" >= (
    SELECT avg("Salary")
    FROM v_employee_info
);
--7.	Using the CTE or the created view, display information about the employees of the programming department, whose salary is higher than the salary of any of the employees of the Marketing Department.
SELECT
    "Full name",
    "Position",
    coalesce("Department", 'No department') as "Department",
    "Salary"
FROM v_employee_info
WHERE "Department" = 'Programming Department'
AND "Salary" > any (
    SELECT "Salary"
    FROM v_employee_info
    WHERE "Department" = 'Marketing Department'
);

--8.Display a list of employees, with the number of business trips each of them has been on. The employee has never been on a business trip, display the value 0 for such an employee (use “coalesce” function if necessary).
SELECT
    e.name as "Full name",
    coalesce(count(bt.trip_id), 0) as trip_count
FROM employee e
LEFT JOIN b_trips bt on e.emp_id = bt.emp_id
GROUP BY e.name
ORDER BY e.name;
--9.Display the list of employees born in May.
SELECT name as "Full name"
FROM employee
WHERE extract(month from birth_date) = 5;
--10.List the employees who have been on a business trip at least once (use the subquery).
SELECT name as "Full name"
FROM employee
WHERE emp_id in (
    SELECT emp_id
    FROM b_trips
);
--11.List the employees who have never been on a business trip (use the subquery).
SELECT name as "Full name"
FROM employee
WHERE emp_id not in (
    SELECT emp_id
    FROM b_trips
);
--12.	Display the names of employees from the programming department (query 1) whose salary is less than 180,000 rubles (query 2). Use a combination of the two queries using the union/intersect/except operations.
SELECT "Full name"
FROM v_employee_info
WHERE "Department" = 'Programming Department'

INTERSECT

SELECT "Full name"
FROM v_employee_info
WHERE "Salary" < 180000;

-- 6. PL/pgSQL FUNCTIONS & SKILLS DATA MODEL

-- First option
CREATE OR REPLACE FUNCTION sum_int (x int, y int) returns int AS $$
 	BEGIN
 	RETURN x + y;
 	END;
$$ LANGUAGE plpgsql;

SELECT sum_int (9, 12);

-- Second option
CREATE OR REPLACE FUNCTION sum_int2 (x int, y int, OUT result int)
AS $$
 BEGIN
 result := x + y;
 END;
$$ LANGUAGE plpgsql

SELECT sum_int2 (5, 3);

--1.Create a function that returns the number of employees in the company.
CREATE OR REPLACE FUNCTION emp_count() returns int AS $$
    BEGIN
    RETURN (select count(*) FROM employee);
END;
$$ LANGUAGE plpgsql;

SELECT emp_count();

-- 2 Create a function that returns the number of employees in the company and their average age.
CREATE OR REPLACE FUNCTION employee_stats()
RETURNS table (employee_count bigint, average_age numeric) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*)::bigint, AVG(EXTRACT(YEAR FROM age(birth_date)))::numeric
    FROM employee;
END;
$$
LANGUAGE plpgsql;

SELECT * from employee_stats();

-- 3 Create a function that adds data to the b_trips table. Function parameters: the employee's name, the date of the start of the business trip, the city of the business trip, and the number of business trip days.
CREATE OR REPLACE FUNCTION add_business_trip(
    emp_name varchar,
    start_date date,
    city varchar,
    days integer
)
RETURNS void AS
$$
DECLARE
    v_emp_id integer;
BEGIN
    -- Находим emp_id по имени сотрудника
    SELECT emp_id INTO v_emp_id
    FROM employee
    WHERE name = emp_name;

    -- Если сотрудник не найден, выдаем ошибку
    IF v_emp_id IS NULL THEN
        RAISE EXCEPTION 'Сотрудник с именем "%" не найден', emp_name;
    END IF;

    -- Вставляем запись в b_trips
    INSERT INTO b_trips (emp_id, place, trip_period)
    VALUES (v_emp_id, city, daterange(start_date, start_date + days, '[]'));
END;
$$
LANGUAGE plpgsql;

-- Проверка:
-- 1. Посмотрим всех сотрудников
SELECT name FROM employee;

-- 2. Выберите существующее имя (например, 'Ivan Venediktov', если он есть) и выполните функцию
SELECT add_business_trip('Ivan Venediktov', '2026-03-20', 'Saint Petersburg', 4);

-- 3. Проверим результат (последние добавленные командировки)
SELECT * FROM b_trips ORDER BY trip_id DESC LIMIT 5;


-- 4 The same task 2

-- 5 Create a function that returns the number of employees sent on a business trip in a given month and the average duration of business trips in that month. If the business trip has not been closed yet (there is no end date), use the current date to calculate the duration.
CREATE OR REPLACE FUNCTION get_trip_stats_by_month(
    month integer,
    year integer
)
RETURNS TABLE (employee_count bigint, avg_duration numeric) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT emp_id)::bigint,
        AVG(
            CASE
                WHEN upper_inf(trip_period) THEN (CURRENT_DATE - lower(trip_period))::numeric
                ELSE (upper(trip_period) - lower(trip_period))::numeric
            END
        )::numeric
    FROM b_trips
    WHERE EXTRACT(YEAR FROM lower(trip_period)) = year
      AND EXTRACT(MONTH FROM lower(trip_period)) = month;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM get_trip_stats_by_month(10, 2024);

-- 6 Create database objects to store information about the skills required by employees for a particular position. In addition to the skill name, it is also necessary to store information about the level of this skill for a specific position (low, medium, high).
 CREATE TABLE IF NOT EXISTS skill
(
	skill_id serial,
	skill_name varchar(255) NOT NULL,
	CONSTRAINT skill_pkey PRIMARY KEY (skill_id)
);

CREATE TYPE skills_level AS ENUM('low', 'medium', 'high');

CREATE TABLE IF NOT EXISTS position_skills
(
	pos_skill_id serial,
	pos_id smallint NOT NULL,
	skill_id int NOT NULL,
	level skills_level,
	CONSTRAINT pos_skill_pkey PRIMARY KEY (pos_skill_id),
	CONSTRAINT pos_skill_fkey FOREIGN KEY (pos_id) REFERENCES position (pos_id),
	CONSTRAINT pos_skill_fkey_2 FOREIGN KEY (skill_id) REFERENCES skill (skill_id)
);

-- 7 Create the “add_skills” function to insert data about the skills required for the position. Function parameters: job title, skill name, and skill level.
CREATE FUNCTION add_skills(skill_param varchar, pos_title_param varchar, level_param skills_level)
RETURNS void AS $$
DECLARE skill_variable int;
BEGIN
	SELECT skill_id
	INTO skill_variable
	FROM skill
	WHERE skill_name = skill_param;

	IF skill_variable IS NULL THEN
		INSERT INTO skill (skill_name)
		VALUES (skill_param);
	END IF;

	INSERT INTO position_skills (skill_id, pos_id, level)
	VALUES ((SELECT skill_id FROM skill WHERE skill_name = skill_param),
		   	(SELECT pos_id FROM position WHERE pos_title=pos_title_param),
		   	level_param);
END;
$$
LANGUAGE plpgsql

-- 8 Insert data using created function:
SELECT add_skills('writing SQL-queries', 'Lead Developer', 'medium');
SELECT add_skills('writing SQL-queries', 'Senior Developer', 'high');
SELECT add_skills('writing SQL-queries', 'QA Specialist', 'low');
SELECT add_skills('knowledge of Python', 'Lead Developer', 'medium');
SELECT add_skills('knowledge of Python', 'Senior Developer', 'high');
SELECT add_skills('knowledge of Python', 'QA Specialist', 'low');
SELECT add_skills('code refactoring', 'Lead Developer', 'high');
SELECT add_skills('code refactoring', 'Senior Developer', 'medium');
SELECT add_skills('working with version control systems (Git)', 'Lead Developer', 'high');
SELECT add_skills('working with version control systems (Git)', 'Senior Developer', 'high');
SELECT add_skills('statistics', 'Marketing Analyst', 'high');

-- 9 Create a function that compares the average salary in 2 departments and returns the name of the department with the highest salary. The function must have 2 input parameters (for the name of each department).
CREATE OR REPLACE FUNCTION compare_dept_avg_salary(
    dept_name1 varchar,
    dept_name2 varchar
)
RETURNS varchar AS
$$
DECLARE
    dept_id1 integer;
    dept_id2 integer;
    avg_salary1 numeric;
    avg_salary2 numeric;
BEGIN
    -- Получаем ID отделов по их названиям
    SELECT dep_id INTO dept_id1
    FROM department
    WHERE dep_name = dept_name1;

    SELECT dep_id INTO dept_id2
    FROM department
    WHERE dep_name = dept_name2;

    -- Проверяем, что отделы существуют
    IF dept_id1 IS NULL THEN
        RAISE EXCEPTION 'Отдел "%" не найден', dept_name1;
    END IF;
    IF dept_id2 IS NULL THEN
        RAISE EXCEPTION 'Отдел "%" не найден', dept_name2;
    END IF;

    -- Средняя зарплата в первом отделе (через сотрудников и их должности)
    SELECT COALESCE(AVG(p.base_salary), 0) INTO avg_salary1
    FROM employee e
    JOIN position p ON e.pos_id = p.pos_id
    WHERE p.dep_id = dept_id1;

    -- Средняя зарплата во втором отделе
    SELECT COALESCE(AVG(p.base_salary), 0) INTO avg_salary2
    FROM employee e
    JOIN position p ON e.pos_id = p.pos_id
    WHERE p.dep_id = dept_id2;

    -- Сравниваем и возвращаем результат
    IF avg_salary1 > avg_salary2 THEN
        RETURN dept_name1;
    ELSIF avg_salary2 > avg_salary1 THEN
        RETURN dept_name2;
    ELSE
        RETURN dept_name1 || ' (средние зарплаты равны)';
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT compare_dept_avg_salary('Marketing Department', 'HR Department');

-- 10 Create a function that compares the average salary in 3 departments and returns the name of the department with the highest salary. The function must have 3 input parameters (for the name of each department).
CREATE OR REPLACE FUNCTION compare_three_depts(
    dept_name1 varchar,
    dept_name2 varchar,
    dept_name3 varchar
)
RETURNS varchar AS
$$
DECLARE
    dept_id1 integer;
    dept_id2 integer;
    dept_id3 integer;
    avg_salary1 numeric;
    avg_salary2 numeric;
    avg_salary3 numeric;
BEGIN
    -- Получаем ID отделов по названиям
    SELECT dep_id INTO dept_id1 FROM department WHERE dep_name = dept_name1;
    SELECT dep_id INTO dept_id2 FROM department WHERE dep_name = dept_name2;
    SELECT dep_id INTO dept_id3 FROM department WHERE dep_name = dept_name3;

    -- Проверяем существование каждого отдела
    IF dept_id1 IS NULL THEN
        RAISE EXCEPTION 'Отдел "%" не найден', dept_name1;
    END IF;
    IF dept_id2 IS NULL THEN
        RAISE EXCEPTION 'Отдел "%" не найден', dept_name2;
    END IF;
    IF dept_id3 IS NULL THEN
        RAISE EXCEPTION 'Отдел "%" не найден', dept_name3;
    END IF;

    -- Средняя зарплата в первом отделе
    SELECT COALESCE(AVG(p.base_salary), 0) INTO avg_salary1
    FROM employee e
    JOIN position p ON e.pos_id = p.pos_id
    WHERE p.dep_id = dept_id1;

    -- Во втором отделе
    SELECT COALESCE(AVG(p.base_salary), 0) INTO avg_salary2
    FROM employee e
    JOIN position p ON e.pos_id = p.pos_id
    WHERE p.dep_id = dept_id2;

    -- В третьем отделе
    SELECT COALESCE(AVG(p.base_salary), 0) INTO avg_salary3
    FROM employee e
    JOIN position p ON e.pos_id = p.pos_id
    WHERE p.dep_id = dept_id3;

    -- Сравниваем и возвращаем отдел с наибольшей средней
    IF avg_salary1 >= avg_salary2 AND avg_salary1 >= avg_salary3 THEN
        RETURN dept_name1;
    ELSIF avg_salary2 >= avg_salary1 AND avg_salary2 >= avg_salary3 THEN
        RETURN dept_name2;
    ELSE
        RETURN dept_name3;
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT compare_three_depts('Marketing Department', 'HR Department', 'Programming Department');

-- 11 List all the positions that require at least one of the skills required for the position of “lead developer”.
SELECT DISTINCT p.pos_title
FROM position p
JOIN position_skills ps ON p.pos_id = ps.pos_id
WHERE ps.skill_id IN (
    SELECT skill_id
    FROM position_skills
    WHERE pos_id = (SELECT pos_id FROM position WHERE pos_title = 'Lead Developer')
)
ORDER BY p.pos_title;

-- 12 List the positions that require all the skills required for the “lead developer” position. The lead developer himself should not be represented in the sample.
WITH lead_skills AS (
    -- Все skill_id, необходимые для Lead Developer
    SELECT skill_id
    FROM position_skills
    WHERE pos_id = (SELECT pos_id FROM position WHERE pos_title = 'Lead Developer')
)
SELECT p.pos_title
FROM position p
WHERE p.pos_id != (SELECT pos_id FROM position WHERE pos_title = 'Lead Developer')
  AND NOT EXISTS (                                     -- для каждого навыка Lead Developer
      SELECT 1
      FROM lead_skills ls
      WHERE NOT EXISTS (                               -- проверяем, есть ли он у текущей позиции
          SELECT 1
          FROM position_skills ps
          WHERE ps.pos_id = p.pos_id
            AND ps.skill_id = ls.skill_id
      )
  )
ORDER BY p.pos_title;


-- 7. WINDOW FUNCTIONS & ACCRUAL ANALYTICS

SET search_path to staff


CREATE TABLE IF NOT EXISTS accrual
(
	acc_id smallserial NOT NULL,
	acc_date timestamp,
	emp_id int NOT NULL,
	amount numeric(10,2),
	CONSTRAINT acc_pkey PRIMARY KEY (acc_id),
	CONSTRAINT acc_fkey FOREIGN KEY (emp_id)
		REFERENCES employee (emp_id)
)


INSERT INTO accrual (acc_date, emp_id, amount)
VALUES
('2024-11-22 17:26:55',4,40032.00),
('2024-11-19 09:42:40',6,80450.00),
('2024-11-10 18:06:43',2,30819.00),
('2024-11-08 02:09:33',1,20580.00),
('2024-11-17 14:33:36',6,50639.00),
('2024-11-05 19:19:52',6,40614.00),
('2024-11-17 19:15:46',4,30650.00),
('2024-11-09 11:14:33',5,80603.00),
('2024-11-15 16:32:09',10,40786.00),
('2024-11-17 09:06:50',3,7013.00),
('2024-11-08 05:20:27',9,40451.00),
('2024-11-23 19:17:16',5,60053.00),
('2024-10-28 03:31:00',1,30379.00),
('2024-10-29 20:46:28',1,5090.00),
('2024-11-19 20:16:01',10,60781.00),
('2024-11-10 09:40:57',10,50034.00),
('2024-11-19 08:07:12',5,60225.00),
('2024-11-06 02:07:12',3,60933.00),
('2024-11-01 13:35:05',9,9098.00),
('2024-10-28 21:35:14',6,90275.00)
;


--3.For each employee, output the employee's name, department, salary, average salary for each department, and the difference between the employee's salary and the average salary for their department.
SELECT
	name,
	dep_name,
	base_salary,
	avg(base_salary) over (partition by d.dep_id) as avg_department,
	base_salary - avg(base_salary) over (partition by d.dep_id) AS salary_difference
FROM employee
JOIN position p on employee.pos_id = p.pos_id
JOIN department d on d.dep_id = p.dep_id

--4.Create a view that contains information about employee benefits. The view should contain the following columns: the employee's name, the date and time of the accrual, and the amount of the accrual.
CREATE OR REPLACE VIEW emp_acc_view as
SELECT name, acc_date, amount
FROM employee e
LEFT JOIN accrual a on e.emp_id = a.emp_id
-- 5.	Output the difference between each employee's accrual and the minimum/maximum accrual for that employee.
SELECT
	name,
	amount,
	amount - min(amount) over (partition by e.emp_id) as diff_min_acc,
	max(amount) over (partition by e.emp_id) - amount as diff_max_acc
FROM employee e
JOIN accrual a on e.emp_id = a.emp_id

--6.Use the window function to calculate the total amount of accruals for each employee.

SELECT
	name,
	amount,
	sum(amount) over (partition by e.emp_id) as sum_of_acc
FROM employee e
JOIN accrual a on e.emp_id = a.emp_id

--7.	For each employee, output the accumulated amount of accruals for each date with accrual.
SELECT
	name,
	acc_date,
	amount,
	round(sum(amount) over date_window,2) AS cumulative_accrual
FROM employee e
JOIN accrual a on e.emp_id = a.emp_id
window date_window as (
	partition by e.emp_id order by acc_date)

--8.Calculate the average amount of accruals for each employee in the range of 8 days (8 days before and 8 days after) from the current accrual. Additionally, print the boundaries of each interval.

SELECT
	name,
	acc_date,
	acc_date - interval '8 days' as eight_days_before,
	acc_date + interval '8 days' as eight_days_after,
	amount,
	round(avg(amount)over (
	partition by name order by acc_date
	range between interval '8 days' preceding and interval '8 days' following),2) as avg_acc_8_days
FROM employee e
JOIN accrual a on e.emp_id = a.emp_id

--9.For each employee accrual, output the difference between the current and the previous accrual.
select
    name,
    acc_date,
    amount,
    round(amount - lag(amount) over (partition by e.emp_id order by acc_date), 2)
	as diff_acc
from employee e
join accrual a on e.emp_id = a.emp_id

--10.For each employee accrual, output the difference between the current and the next accrual. 
select
    name,
    acc_date,
    amount,
    round(amount - lead(amount) over (partition by e.emp_id order by acc_date), 2)
	as diff_acc
from employee e
join accrual a on e.emp_id = a.emp_id

--11.Display a list of employees for whom the average deviation between the current and previous accrual does not exceed 20,000 rubles.  
with diff_acc_cte as (
    select
        name,
        round(amount - lag(amount) over (partition by e.emp_id order by acc_date), 2) as diff_acc
    from employee e
    join accrual a on e.emp_id = a.emp_id
)
select name
from diff_acc_cte
group by name
having avg(abs(diff_acc)) <= 20000

--12.For each employee, calculate the average salary of his closest "neighbours" in the department. "Neighbours" are defined by salary size (i.e. the closest employee who gets less and the closest employee who gets more). 
with table_dep as (
    select *
    from employee e
    join position p on p.pos_id = e.pos_id
)
select
    name,
    dep_id,
    base_salary,
    round(avg(base_salary) over(
        partition by dep_id
        order by base_salary
        rows between 1 preceding and 1 following), 2) as avg_neighbours_salary
from table_dep
order by dep_id, base_salary

--13.Display the rating of departments by the number of employees working in each of them.  
select
    d.dep_name,
    count(emp_id) as emp_count,
    dense_rank() over (order by count(*) desc) as rating
from employee e
join position p on p.pos_id = e.pos_id
join department d on d.dep_id = p.dep_id
group by d.dep_id, d.dep_name
order by rating

--14.	For each employee, withdraw the largest 50% of the accruals.
with ranked as (
    select
        name,
        acc_date,
        amount,
        ntile(2) over (partition by e.emp_id order by amount desc) as tile
    from employee e
    join accrual a on a.emp_id = e.emp_id
)
select name, amount
from ranked
where tile = 1
order by name, amount desc


select
    name,
    acc_date,
    amount,
    round(amount - lag(amount) over (partition by e.emp_id order by acc_date), 2)
	as diff_acc
from employee e
join accrual a on e.emp_id = a.emp_id



