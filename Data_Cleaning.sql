-- data cleaning


select *
from layoffs;

-- remove duplicates
-- standardize the data

CREATE TABLE layoff_stages
LIKE layoffs;

SELECT *
FROM layoff_stages;

insert layoff_stages
select *
from layoffs;

-- remove duplicates
-- just like grouping
-- null values or blank values
-- remove any columns or row

SELECT *,
row_number() over(
PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`) AS row_num
FROM layoff_stages;

with duplicate_cte as
(
SELECT *,
row_number() over(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM layoff_stages
)
select*
from duplicate_cte
where row_num>1;

select*
from layoff_stages
where company = 'casper';


CREATE TABLE `layoff_stages2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select*
from layoff_stages2
where row_num>1;

insert into layoff_stages2
select *,
row_number() over(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM layoff_stages;


delete
from layoff_stages2
where row_num>1;



select*
from layoff_stages2;


-- standardize the data

select company, trim(company)
from layoff_stages2;

UPDATE layoff_stages2
set company = trim(company); 

select *
from layoff_stages2
where industry like 'crypto%';

 -- change cryptocurrency to crypto to make it unique
 
update layoff_stages2
set industry = 'crypto'
where industry like 'crypto%';

select distinct country
from layoff_stages2
order by 1;

update layoff_stages2
set country = 'United States'
where country like 'United States%';


  -- change date format from text
select `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') 
from layoff_stages2;

 -- to change to identify date arrangement
update layoff_stages2
set `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

select `date`
from layoff_stages2;

 -- change from text to date
 alter table layoff_stages2
 modify column `date` date;
 
select *
from layoff_stages2
where company = 'airbnb';

-- update blank or null industry with a known industry that share thesame company and location name

update layoff_stages2
set industry = null
where industry = ' ';

select l1.industry, l2.industry
from layoff_stages2 l1
join layoff_stages2 l2
	on l1.company=l2.company
where l1.industry is null 
and l2.industry is not null;

update layoff_stages2 l1
join layoff_stages2 l2
	on l1.company=l2.company
    and l1.location=l2.location
set l1.industry=l2.industry
where l1.industry is null 
and l2.industry is not null;

select*
from layoff_stages2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


DELETE from layoff_stages2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

select*
from layoff_stages2;

 -- TO DELEETE ROW NUM
 ALTER TABLE layoff_stages2
 drop column row_num;
 
select*
from layoff_stages2
where percentage_laid_off =1
order by funds_raised_millions desc;

 -- to determine sum of total layoffs by each company
select company, sum(total_laid_off)
from layoff_stages2
group by company
order by 2 desc;

 -- to determine the starting and ending date of layoffs
select min(`date`), max(`date`)
from layoff_stages2;

 -- to determine the starting and ending date of layoffs
select industry, sum(total_laid_off)
from layoff_stages2
group by industry
order by 2 desc;


 -- to determine sum of total layoffs by each country
select country, sum(total_laid_off)
from layoff_stages2
group by country
order by 2 desc;

 -- to determine sum of total layoffs by date
select `date`, sum(total_laid_off)
from layoff_stages2
group by `date`
order by 2 desc;

 -- to determine sum of total layoffs by year
select year(`date`), sum(total_laid_off)
from layoff_stages2
group by year(`date`)
order by 2 desc;


 -- to determine sum of total layoffs by stage
select stage, sum(total_laid_off)
from layoff_stages2
group by stage
order by 2 desc;

 -- to determine sum of rolling cumulative total layoffs 
select substring(`date`, 1,7) as `month`, sum(total_laid_off)
from layoff_stages2
where substring(`date`, 1,7) is not null
group by `month`
order by 1 asc;

-- rolling sum
with rolling_total as
(
select substring(`date`, 1,7) as `month`, sum(total_laid_off) as total_off
from layoff_stages2
where substring(`date`, 1,7) is not null
group by `month`
order by 1 asc
)
select `month`, total_off, sum(total_off) over(order by `month`) as rolling_total
from rolling_total;

select company, year(`date`) as years, sum(total_laid_off)
from layoff_stages2
group by company, year(`date`)
order by 1 asc;

 -- to RANK RATES OF LAYOFF PER YEAR
 with company_year(company, years, total_laid_off) as
 (
 select company, year(`date`), sum(total_laid_off)
from layoff_stages2
group by company, year(`date`)
)
select *, dense_rank() over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
order by ranking asc;