
-- LUNGS CANCER DATA EXPLORATION

select* from lung_cancer_prediction_dataset;

-- show population size of the affected by country
select Country, Population_Size, Gender
from lung_cancer_prediction_dataset
group by Gender, Country, Population_Size
order by Country asc;



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


-- "Age Group Distribution by Country with Ranked Classification"

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

-- showing total number family with or no family history of cancer by each countrt
select Country, Family_History, count(Family_History) from lung_cancer_prediction_dataset
group by Country, Family_History
order by Country, Family_History ;

-- survival year
select Country, Survival_Years
from lung_cancer_prediction_dataset
group by Country, Survival_Years
order by Country;

-- showing exposure rate
select Country, Air_pollution_Exposure, Occupational_Exposure
from lung_cancer_prediction_dataset
group by  Country, Air_pollution_Exposure, Occupational_Exposure
order by  Country, Air_pollution_Exposure, Occupational_Exposure;

select Country, Air_pollution_Exposure, count(Air_Pollution_Exposure)
from lung_cancer_prediction_dataset
group by  Country, Air_pollution_Exposure
order by  Country, Air_pollution_Exposure;

-- showing rate of Indoor_Pollution
select Country, Indoor_Pollution, count(Indoor_Pollution)
from lung_cancer_prediction_dataset
group by  Country, Indoor_Pollution
order by  Country, Indoor_Pollution;


-- Annual cancer deathrate
select distinct Country, Annual_Lung_Cancer_Deaths
from lung_cancer_prediction_dataset
group by Country, Annual_Lung_Cancer_Deaths;


-- Lung_Cancer_Prevalence_Rate
select Country, Lung_Cancer_Prevalence_Rate
from lung_cancer_prediction_dataset
group by Country, Lung_Cancer_Prevalence_Rate;
