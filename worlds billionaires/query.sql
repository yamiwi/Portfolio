# Get familiarized with dataset
-- rank: The ranking of the billionaire in terms of wealth.
-- finalWorth: The final net worth of the billionaire in U.S. dollars.
-- category: The category or industry in which the billionaire's business operates.
-- personName: The full name of the billionaire.
-- age: The age of the billionaire.
-- country: The country in which the billionaire resides.
-- city: The city in which the billionaire resides.
-- source: The source of the billionaire's wealth.
-- industries: The industries associated with the billionaire's business interests.
-- countryOfCitizenship: The country of citizenship of the billionaire.
-- organization: The name of the organization or company associated with the billionaire.
-- selfMade: Indicates whether the billionaire is self-made (True/False).
-- status: "D" represents self-made billionaires (Founders/Entrepreneurs) and "U" indicates inherited or unearned wealth.
-- gender: The gender of the billionaire.
-- birthDate: The birthdate of the billionaire.
-- lastName: The last name of the billionaire.
-- firstName: The first name of the billionaire.
-- title: The title or honorific of the billionaire.
-- date: The date of data collection.
-- state: The state in which the billionaire resides.
-- residenceStateRegion: The region or state of residence of the billionaire.
-- birthYear: The birth year of the billionaire.
-- birthMonth: The birth month of the billionaire.
-- birthDay: The birth day of the billionaire.
-- cpi_country: Consumer Price Index (CPI) for the billionaire's country.
-- cpi_change_country: CPI change for the billionaire's country.
-- gdp_country: Gross Domestic Product (GDP) for the billionaire's country.
-- gross_tertiary_education_enrollment: Enrollment in tertiary education in the billionaire's country.
-- gross_primary_education_enrollment_country: Enrollment in primary education in the billionaire's country.
-- life_expectancy_country: Life expectancy in the billionaire's country.
-- tax_revenue_country_country: Tax revenue in the billionaire's country.
-- total_tax_rate_country: Total tax rate in the billionaire's country.
-- population_country: Population of the billionaire's country.
-- latitude_country: Latitude coordinate of the billionaire's country.
-- longitude_country: Longitude coordinate of the billionaire's country.

USE billionaires;

SELECT * FROM billionaires LIMIT 25;

-- Check for missing values
SELECT COUNT(*) FROM billionaires WHERE `billionaires`.`﻿rank` = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE finalWorth = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE category = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE personName = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE age = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE country = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE source = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE selfMade = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE gender = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE birthDate = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE title = ''; -- 2067
SELECT COUNT(*) FROM billionaires WHERE cpi_country = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE gdp_country = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE total_tax_rate_country = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE latitude_country = ''; -- 0
SELECT COUNT(*) FROM billionaires WHERE longitude_country = ''; -- 0

-- Check the number of people living in the different country than where they were born
SELECT * FROM billionaires WHERE country != countryOfCitizenship;


-- Check for duplicates
SELECT `billionaires`.`﻿rank` FROM billionaires GROUP BY `billionaires`.`﻿rank` HAVING COUNT(*) > 1; -- 117 
SELECT * FROM billionaires INNER JOIN (SELECT `billionaires`.`﻿rank` FROM billionaires GROUP BY `billionaires`.`﻿rank` HAVING COUNT(*) > 1) AS q1 USING(`﻿rank`) LIMIT 10;

SELECT personName FROM billionaires GROUP BY personName HAVING COUNT(*) > 1; -- 2 duplicates
SELECT * FROM billionaires INNER JOIN (SELECT personName FROM billionaires GROUP BY personName HAVING COUNT(*) > 1) AS q USING(personName);
-- They are different people so there is no need to exclude them from the dataset


-- -------------------------------------------------------------Exploratory Data Analysis-----------------------------------------------------------------

-- Declare a variable showing total number of rows in the dataset
SET @total = (SELECT COUNT(*) FROM billionaires);

-- Check the distribution of billionaires by categories of industries in which the billionaires business operates
SELECT category, COUNT(*) AS billionaires FROM billionaires GROUP BY category ORDER BY count(*) DESC;

-- Display the distribution of billionaires ages
WITH age_bins AS (
  SELECT 
    CASE WHEN age BETWEEN 18 
    AND 27 THEN '18-27' WHEN age BETWEEN 28 
    AND 35 THEN '28-35' WHEN age BETWEEN 36 
    AND 45 THEN '36-45' WHEN age BETWEEN 46 
    AND 55 THEN '46-55' WHEN age BETWEEN 56 
    AND 65 THEN '56-65' WHEN age BETWEEN 66 
    AND 75 THEN '66-75' WHEN age BETWEEN 76 
    AND 85 THEN '76-85' WHEN age > 85 THEN '86+' END AS bins 
  FROM 
    billionaires
)
    SELECT bins AS age, COUNT(*) as billionaires, ROUND(COUNT(*) / @total * 100, 2) as percents_of_total FROM age_bins GROUP BY bins ORDER BY 1 DESC;

-- Display year of birth distribution
SELECT YEAR(birthDate) as year_of_birth, COUNT(*) as billionaires FROM billionaires GROUP BY YEAR(birthDate) ORDER BY 1 DESC;

-- Calculate average age of billionaires
SELECT AVG(age) FROM billionaires; -- 65 years

-- Display country related information 
SELECT country, cpi_country,  COUNT(*) as billionaires, COUNT(*) / population_country * 100 as percent_of_country_population FROM billionaires GROUP BY country, population_country, cpi_country ORDER BY 4 DESC, 3 DESC;

-- Explore the source of billionaires income distribution
SELECT source, COUNT(*) as billionaires FROM billionaires GROUP BY source ORDER BY count(*) DESC LIMIT 25;

-- Check how many of billionares are self made or not
SELECT selfMade, COUNT(*) as billionaires, ROUND(COUNT(*) / @total * 100, 2) AS percents_of_total  FROM billionaires GROUP BY selfMade ORDER BY 2 DESC;

-- Check billionaires gender distribution
SELECT gender, COUNT(*) as billionaires, ROUND(COUNT(*) / @total * 100, 2) as percents_of_total FROM billionaires GROUP BY gender ORDER BY count(*) DESC;

-- Check what position person occupies 
SELECT title, COUNT(*) as billionaires FROM billionaires WHERE title != '' GROUP BY title ORDER BY count(*) DESC;


-- -------------------------------------------------------------Create views for future visualizations-------------------------------------------------------------

-- Exlude unnecessary columns and create a view for future visulizations
DROP VIEW IF EXISTS prepared;
CREATE VIEW prepared AS 
SELECT 
  DENSE_RANK() OVER (ORDER BY finalWorth DESC) as rankPos, 
  finalWorth, 
  category, 
  personName, 
  age, 
  CASE WHEN age BETWEEN 18 
    AND 27 THEN '18-27' WHEN age BETWEEN 28 
    AND 35 THEN '28-35' WHEN age BETWEEN 36 
    AND 45 THEN '36-45' WHEN age BETWEEN 46 
    AND 55 THEN '46-55' WHEN age BETWEEN 56 
    AND 65 THEN '56-65' WHEN age BETWEEN 66 
    AND 75 THEN '66-75' WHEN age BETWEEN 76 
    AND 85 THEN '76-85' WHEN age > 85 THEN '86+' END AS bins,
  country, 
  source, 
  CASE WHEN selfMade = 'TRUE' THEN 'Self-Made' ELSE 'Inherited' END as selfMade, 
  CASE WHEN gender = 'M' THEN 'Male' ELSE 'Female' END AS gender, 
  DATE(CONCAT_WS('-', birthYear, birthMonth, birthDay)) as birthDate, 
  IF(title = '', 'Not Specified', title) as title, 
  cpi_country, 
  gdp_country, 
  total_tax_rate_country, 
  population_country,
  latitude_country, 
  longitude_country 
FROM 
  billionaires;

SELECT * FROM prepared LIMIT 25;

-- Calculate the number of billionaires of total country population and create a view for future visualizations
DROP VIEW IF EXISTS billionaires_country;
CREATE VIEW billionaires_country AS 
SELECT 
  country, 
  COUNT(*) as billionaires, 
  population_country,
  CAST(COUNT(*) / population_country AS DECIMAL(9, 9)) as percent_of_total_population 
FROM 
  billionaires 
GROUP BY 
  country, 
  population_country;

SELECT * FROM billionaires_country LIMIT 25;

-- -------------------------------------------------------------These are calculations that i have made in Power Bi------------------------------------------------------------------------------

-- Discover number of billionaires by years of birth
SELECT
  YEAR(birthDate) AS year, 
  COUNT(*) as billionaires
FROM 
  prepared
GROUP BY
  YEAR(birthDate)
ORDER BY 1;

-- Investigate number of billionaires by age bins and splitted by either billionaire's wealth are inherited or self-made
SELECT 
  bins,
  selfMade, 
  COUNT(*) AS billionaires
FROM 
  prepared
GROUP BY 
  bins,
  selfMade
ORDER BY 1;

-- Investigate number of billionaires by country
SELECT
  country,
  COUNT(*) AS billionaires
FROM 
  prepared
GROUP BY 
  country
ORDER BY 2 DESC;

-- Investigate number of billionaires from the total country population
SELECT 
  country, 
  CAST(COUNT(*) / population_country AS DECIMAL(9, 9)) as percent_of_total_population 
FROM 
  billionaires 
GROUP BY 
  country, 
  population_country
ORDER BY 2 DESC;

-- Investigate billionaires sources of income 
SELECT 
  category,
  COUNT(*) AS billionaires
FROM 
  prepared
GROUP BY 
  category
ORDER BY 2 DESC;

-- Display gender distribution
SELECT 
  gender, 
  COUNT(*) AS billionaires
FROM 
  prepared 
GROUP BY
  gender
ORDER BY 2 DESC;

-- Investigate either billionaire's wealth are self-made or inherited distribution
SELECT 
  selfMade,
  COUNT(*) AS billionaires
FROM 
  prepared
GROUP BY
  selfMade
ORDER BY 2 DESC;


