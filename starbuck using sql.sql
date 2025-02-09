-- view file after import
select*
from project.project1;

-- Rename Table
rename table project.project1 to project.starbuck_location;

-- to select table
use starbuck_location;

select*
from starbuck_location;


-- view datatypes
describe starbuck_location;

-- view 
SELECT 
    country, 
    `Ownership Type`, 
    COUNT(`Ownership Type`) AS num_ownership, 
    RANK() OVER (PARTITION BY country ORDER BY COUNT(`Ownership Type`) DESC) AS ranks
FROM starbuck_location
GROUP BY country, `Ownership Type`
ORDER BY country, ranks;

SELECT 
   RANK() OVER (PARTITION BY country ORDER BY COUNT(City) DESC) AS ranks, country, 
    City, 
    COUNT(City) AS num_city
FROM starbuck_location
GROUP BY country, City
ORDER BY country, ranks;

