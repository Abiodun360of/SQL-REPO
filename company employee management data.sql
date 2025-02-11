-- Create Database
CREATE DATABASE MY_COMPANY_DATABASE;
USE MY_COMPANY_DATABASE;

-- Create Departments Table
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_head VARCHAR(100) NOT NULL
);

-- Create Employees Table
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INT,
    date_of_birth DATE NOT NULL,
    hire_date DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Create Salaries Table
CREATE TABLE salaries (
    salary_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    base_salary DECIMAL(10,2) NOT NULL,
    last_increment_date DATE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Create Attendance Table
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    attendance_date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Leave') NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Create Retirees Table
CREATE TABLE retirees (
    retiree_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    retirement_date DATE NOT NULL,
    retirement_payoff DECIMAL(12,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Create Procedure for Employee Promotion
DELIMITER $$
CREATE PROCEDURE promote_employee(IN emp_id INT, IN new_salary DECIMAL(10,2))
BEGIN
    UPDATE salaries SET base_salary = new_salary, last_increment_date = CURDATE()
    WHERE employee_id = emp_id;
END $$
DELIMITER ;

-- Create Procedure to Calculate Bonus
DELIMITER $$
CREATE PROCEDURE calculate_bonus(IN emp_id INT, OUT bonus DECIMAL(10,2))
BEGIN
    DECLARE base DECIMAL(10,2);
    SELECT base_salary INTO base FROM salaries WHERE employee_id = emp_id;
    SET bonus = base * 0.10; -- 10% bonus
END $$
DELIMITER ;

-- Create Trigger to Validate Salary Insertion
DELIMITER $$
CREATE TRIGGER before_insert_salary
BEFORE INSERT ON salaries
FOR EACH ROW
BEGIN
    IF NEW.base_salary < 1000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary cannot be less than 1000';
    END IF;
END $$
DELIMITER ;

-- Create Event to Move Retirees (Run Monthly)
SET GLOBAL event_scheduler = ON;
DELIMITER $$
CREATE EVENT move_retirees
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    INSERT INTO retirees (employee_id, first_name, last_name, department_name, retirement_date, retirement_payoff)
    SELECT e.employee_id, e.first_name, e.last_name, d.department_name, CURDATE(), s.base_salary * 0.5
    FROM employees e
    JOIN salaries s ON e.employee_id = s.employee_id
    JOIN departments d ON e.department_id = d.department_id
    WHERE TIMESTAMPDIFF(YEAR, e.date_of_birth, CURDATE()) >= 65;
    
    DELETE FROM employees WHERE TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 65;
    DELETE FROM salaries WHERE employee_id IN (SELECT employee_id FROM retirees);
END $$
DELIMITER ;

-- Advanced Reports Queries

-- 1. Get Employees with Highest Salaries per Department
SELECT e.first_name, e.last_name, d.department_name, s.base_salary
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE s.base_salary = (SELECT MAX(s2.base_salary) FROM salaries s2 WHERE s2.employee_id = e.employee_id);

-- 2. Count of Employees per Department
SELECT d.department_name, COUNT(e.employee_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name;

-- 3. Monthly Salary Expense per Department
SELECT d.department_name, SUM(s.base_salary) AS total_salary_expense
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN salaries s ON e.employee_id = s.employee_id
GROUP BY d.department_name;

-- 4. Employee Attendance Summary
SELECT e.first_name, e.last_name, a.status, COUNT(a.attendance_date) AS total_days
FROM employees e
JOIN attendance a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, a.status;

-- 5. List of Employees Eligible for Promotion (Based on Last Increment Date)
SELECT e.first_name, e.last_name, s.base_salary, s.last_increment_date
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
WHERE s.last_increment_date <= DATE_SUB(CURDATE(), INTERVAL 2 YEAR);
