
-- LUNGS CANCER DATA EXPLORATION

select* from lung_cancer_prediction_dataset;

-- 1 check missing values 
SELECT Country, COUNT(*) - COUNT(Country) AS missing_values_country, count(*)- count(Population_Size) as missing_values_population
FROM lung_cancer_prediction_dataset
GROUP BY Country;

-- 2 count total records
SELECT COUNT(*) AS Total_Records FROM lung_cancer_prediction_dataset;
SELECT DISTINCT Country FROM lung_cancer_prediction_dataset;

-- 3. Show male smoker
SELECT * 
FROM lung_cancer_prediction_dataset 
WHERE Gender = 'Male' AND Smoker = 'Yes';

-- 4 show old smoke diagnoised with lung cancer
SELECT * FROM lung_cancer_prediction_dataset WHERE Age > 60 AND Lung_Cancer_Diagnosis = 'Yes';

-- 5 show passive smokers in usa
SELECT * 
FROM lung_cancer_prediction_dataset 
WHERE Country = 'USA' AND Passive_Smoker = 'Yes';

-- 6 show population size of each affected country
select Country, Population_Size, Gender
from lung_cancer_prediction_dataset
group by Gender, Country, Population_Size
order by Country asc;

-- 7 The number of lung cancer cases per country
SELECT Country, COUNT(*) AS Cases FROM lung_cancer_prediction_dataset WHERE Lung_Cancer_Diagnosis = 'Yes' GROUP BY Country ORDER BY Cases DESC;

-- 8 the Average Age of Lung Cancer Patients
SELECT AVG(Age) AS Avg_Age FROM lung_cancer_prediction_dataset WHERE Lung_Cancer_Diagnosis = 'Yes';

-- 9 show ratio of smoker to non-smoker
SELECT Smoker, COUNT(*) FROM lung_cancer_prediction_dataset GROUP BY Smoker;


-- 10 distribution of lung cancer cases across different age groups within each country. 
-- It categorizes patients into three age groups—Young, Middle-aged, and Old
WITH age_grouping AS (
    SELECT *,
        CASE 
            WHEN age < 25 THEN 'Young'
            WHEN age BETWEEN 25 AND 50 THEN 'Middle-aged'
            ELSE 'Old'
        END AS age_group
    FROM lung_cancer_prediction_dataset
)
SELECT 
    Country, 
    age_group,
    DENSE_RANK() OVER(PARTITION BY Country ORDER BY 
        CASE age_group 
            WHEN 'Young' THEN 1 
            WHEN 'Middle-aged' THEN 2 
            ELSE 3 
        END
    ) AS age_group_rank,  -- 1 = Young, 2 = Middle-aged, 3 = Old
    Age, 
    Early_Detection, Smoker
    Years_of_Smoking, 
    Cigarettes_per_Day, 
    Passive_Smoker, 
    Lung_Cancer_Diagnosis, 
    Cancer_Stage
FROM age_grouping
ORDER BY Country ASC, age_group_rank ASC;

-- 11 Age Group Distribution of Lung Cancer Cases Across Countries 2
WITH age_grouping AS (
    SELECT 
        Country,
        CASE 
            WHEN age < 25 THEN 'Young'
            WHEN age BETWEEN 25 AND 50 THEN 'Middle-aged'
            ELSE 'Old'
        END AS age_group
    FROM lung_cancer_prediction_dataset
)
SELECT 
    Country, 
    age_group, 
    COUNT(*) AS age_group_count,
    DENSE_RANK() OVER(PARTITION BY Country ORDER BY 
        CASE age_group 
            WHEN 'Young' THEN 1 
            WHEN 'Middle-aged' THEN 2 
            ELSE 3 
        END
    ) AS age_group_rank
FROM age_grouping
GROUP BY Country, age_group
ORDER BY Country ASC, age_group_rank ASC;

-- 12 Distribution of Lung Cancer Patients by Cancer Stage
SELECT Cancer_Stage, COUNT(*) AS Patients 
FROM lung_cancer_prediction_dataset 
WHERE Lung_Cancer_Diagnosis = 'Yes' 
GROUP BY Cancer_Stage 
ORDER BY Patients DESC;

-- 13 Average Survival Years of Lung Cancer Patients by Gender
SELECT Gender, AVG(Survival_Years) 
FROM lung_cancer_prediction_dataset 
WHERE Lung_Cancer_Diagnosis = 'Yes' 
GROUP BY Gender;

-- 14 Average Survival Years of Lung Cancer Patients by age group
SELECT CASE 
            WHEN age < 25 THEN 'Young'
            WHEN age BETWEEN 25 AND 50 THEN 'Middle-aged'
            ELSE 'Old'
        END AS age_group, AVG(Survival_Years) 
FROM lung_cancer_prediction_dataset 
WHERE Lung_Cancer_Diagnosis = 'Yes' 
GROUP BY age_group;


-- 15 showing total number family with or no family history of cancer by each countrt
select Country, Family_History, count(Family_History) from lung_cancer_prediction_dataset
group by Country, Family_History
order by Country, Family_History ;

-- 16 survival year
select Country, Survival_Years
from lung_cancer_prediction_dataset
group by Country, Survival_Years
order by Country;

-- 17 showing exposure rate
select Country, Air_pollution_Exposure, Occupational_Exposure
from lung_cancer_prediction_dataset
group by  Country, Air_pollution_Exposure, Occupational_Exposure
order by  Country, Air_pollution_Exposure, Occupational_Exposure;

-- 18 Air pollution exposure by country
select Country, Air_pollution_Exposure, count(Air_Pollution_Exposure)
from lung_cancer_prediction_dataset
group by  Country, Air_pollution_Exposure
order by  Country, Air_pollution_Exposure;

-- 19 showing rate of Indoor_Pollution
select Country, Indoor_Pollution, count(Indoor_Pollution)
from lung_cancer_prediction_dataset
group by  Country, Indoor_Pollution
order by  Country, Indoor_Pollution;


-- 20 Annual cancer deathrate
select distinct Country, Annual_Lung_Cancer_Deaths
from lung_cancer_prediction_dataset
group by Country, Annual_Lung_Cancer_Deaths;


-- 21 Lung_Cancer_Prevalence_Rate
select Country, Lung_Cancer_Prevalence_Rate
from lung_cancer_prediction_dataset
group by Country, Lung_Cancer_Prevalence_Rate;

-- 22 Total Annual Lung Cancer Deaths by Country
SELECT Country, SUM(Annual_Lung_Cancer_Deaths) AS Total_Deaths 
FROM lung_cancer_prediction_dataset 
GROUP BY Country 
ORDER BY Total_Deaths DESC;

-- 23 Comparing Lung Cancer Mortality Rates in Developed vs. Developing Countries
SELECT Developed_or_Developing, AVG(Mortality_Rate) 
FROM lung_cancer_prediction_dataset 
GROUP BY Developed_or_Developing;





