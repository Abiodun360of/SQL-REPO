

-- Automated Employee Retirement System Using MySQL


select * from employee_demographics;
select * from employee_salary;
select * from  parks_departments;


-- Enable event scheduler
SET GLOBAL event_scheduler = ON;


-- create retiree table

CREATE TABLE retirees (
    retiree_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    occupation VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    age INT NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    retirement_date DATE NOT NULL,
    years_of_working INT ,
    retirement_payoff DECIMAL(12,2) 
);

select* FROM employee_demographics
;


DELIMITER $$

CREATE EVENT move_retirees
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    -- Move retired employees to retirees table
    INSERT INTO retirees (employee_id, first_name, last_name, occupation, salary, gender, age, date_of_birth, department_name, retirement_date)
    SELECT 
        ed.employee_id, 
        ed.first_name, 
        ed.last_name, 
        ed.occupation, 
        es.salary, 
        ed.gender, 
        ed.age, 
        ed.date_of_birth, 
        pd.department_name, 
        CURRENT_DATE
    FROM employee_demographics ed
    JOIN employee_salary es ON ed.employee_id = es.employee_id
    JOIN parks_departments pd ON es.dept_id = pd.department_id
    WHERE ed.age >= 70;

    -- Delete matching records from employee_salary
    DELETE es 
    FROM employee_salary es
    JOIN employee_demographics ed ON es.employee_id = ed.employee_id
    WHERE ed.age >= 70;

    -- Delete matching records from employee_demographics
    DELETE FROM employee_demographics WHERE age >= 70;
    
END $$

DELIMITER ;


