
USE middle_east_conflict;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------Demolitions dataset----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM demolitions LIMIT 150;

-- Check for missing values
SELECT COUNT(*) FROM demolitions WHERE `Date of Demolition` = ''; -- 0
SELECT COUNT(*) FROM demolitions WHERE Locality = ''; -- 2
SELECT COUNT(*) FROM demolitions WHERE District = ''; -- 2
SELECT COUNT(*) FROM demolitions WHERE Area = ''; -- 0
SELECT COUNT(*) FROM demolitions WHERE `Housing Units` = ''; -- 0
SELECT COUNT(*) FROM demolitions WHERE `People left Homeless` = ''; -- 0
SELECT COUNT(*) FROM demolitions WHERE `Minors left Homeless` = ''; -- 0
SELECT COUNT(*) FROM demolitions WHERE `Type of Sturcture` = ''; -- 0

SELECT * FROM demolitions WHERE Locality = '' OR District = '';
-- I will exclude this rows since there are no valuable information in 

DROP VIEW IF EXISTS demolitions_view;
CREATE VIEW demolitions_view AS
SELECT
	STR_TO_DATE(`Date of Demolition`, '%m/%d/%Y') AS demolition_date,
    District AS district,
    CAST(`Housing Units` AS UNSIGNED) AS buildings,
    CAST(`People left Homeless` AS UNSIGNED) AS adults_left_homeless,
    CAST(`Minors left Homeless` AS UNSIGNED) AS minors_left_homeless,
    `Type of Sturcture` AS structure_type 
FROM demolitions 
WHERE Locality != '' OR District != '';

SELECT * FROM demolitions_view LIMIT 150;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------People losses---------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS merged;
CREATE VIEW merged AS 
SELECT * FROM palestinians_killed_by_unknown_israeli
UNION
SELECT * FROM palestinians_killed_by_palestinians_for_suspected_collaboration
UNION
SELECT * FROM palestinians_killed_by_israeli_forces
UNION 
SELECT * FROM palestinians_killed_by_israeli_civilians
UNION 
SELECT * FROM israeli_killed_by_palestinians 
UNION
SELECT * FROM israeli_forces_killed_by_palestinians
UNION 
SELECT * FROM foreign_nationals_killed_by_israeli_forces 
UNION
SELECT * FROM foreign_nationals_killed_by_palestinians;

SELECT * FROM merged LIMIT 150;

-- Check for missing values
SELECT COUNT(*) FROM merged WHERE Name = ''; -- 0
SELECT COUNT(*) FROM merged WHERE `Date of event` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE Age = ''; -- 94
SELECT COUNT(*) FROM merged WHERE Citizenship = ''; -- 2
SELECT COUNT(*) FROM merged WHERE `Event location` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE `Event location - District` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE `Event location - Region` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE `Date of death` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE Gender = ''; -- 0
SELECT COUNT(*) FROM merged WHERE `Took part in the hostilities` = ''; -- 997
SELECT COUNT(*) FROM merged WHERE `Place of residence` = ''; -- 178
SELECT COUNT(*) FROM merged WHERE `Place of residence - District` = ''; -- 178
SELECT COUNT(*) FROM merged WHERE `Type of injury` = ''; -- 327
SELECT COUNT(*) FROM merged WHERE Ammunition = ''; -- 6012
SELECT COUNT(*) FROM merged WHERE `Killed By` = ''; -- 0
SELECT COUNT(*) FROM merged WHERE Notes = ''; -- 325

SELECT * FROM merged WHERE Age = '';

SELECT * FROM merged WHERE Citizenship = ''; # replace missing values for Italian Jordanian
SELECT DISTINCT Citizenship FROM merged;

SELECT * FROM merged WHERE `Took part in the hostilities` = '';
SELECT DISTINCT `Took part in the hostilities` FROM merged; -- Since participated in hostilities could be only Yes or No any other values are errors and i am going to get rid of them
-- There are some 'Israelis' suspicious values so it is time to investigate them
SELECT * FROM merged WHERE `Took part in the hostilities` = 'Israelis';
SELECT Notes, COUNT(*) FROM merged WHERE `Took part in the hostilities` = 'Israelis' GROUP BY Notes ORDER BY 2 DESC;
-- I noticed that there are a lot of cases like 'suicide' 
SELECT COUNT(`Took part in the hostilities`) FROM merged; -- 12280 rows in total
SELECT COUNT(*) FROM merged WHERE `Took part in the hostilities` = 'Israelis'; -- 987 rows 
SELECT COUNT(*) FROM merged WHERE `Took part in the hostilities` = 'Israelis' AND Notes LIKE '%suicide%'; -- 468 people died in suicide bombing
-- 468 out of 987 (>50% of missing values) people died in suicide bombing. I assume that these people were civilians and had not participated in hostilities
-- I will replace all 'Israelis' records to not participated in hostilities since there are about ~500 people left of 987 who might participated in but in reality this value is much lower so it would not make any difference overall

SELECT * FROM merged WHERE `Place of residence` = '';
SELECT DISTINCT `Place of residence` FROM merged; # set missing values to Unknown

SELECT * FROM merged WHERE `Place of residence - District` = '';
SELECT DISTINCT `Place of residence - District` FROM merged; # set missing values to Unknown

SELECT * FROM merged WHERE `Type of injury` = '';
SELECT DISTINCT `Type of injury` FROM merged; # set missing values to Unknown

SELECT * FROM merged WHERE Notes = '';

SELECT DISTINCT gender FROM merged;

DROP VIEW merged;

DROP VIEW IF EXISTS main;
CREATE VIEW main AS 
with cte AS ( 		-- Make a CTE to be able to rename columns and make a transformations on whole dataset 
	SELECT * FROM palestinians_killed_by_unknown_israeli
	UNION
	SELECT * FROM palestinians_killed_by_palestinians_for_suspected_collaboration
	UNION
	SELECT * FROM palestinians_killed_by_israeli_forces
	UNION 
	SELECT * FROM palestinians_killed_by_israeli_civilians
	UNION 
	SELECT * FROM israeli_killed_by_palestinians 
	UNION
	SELECT * FROM israeli_forces_killed_by_palestinians
	UNION 
	SELECT * FROM foreign_nationals_killed_by_israeli_forces 
	UNION
	SELECT * FROM foreign_nationals_killed_by_palestinians
) 
SELECT 
	NAME as name,
    STR_TO_DATE(`Date of death`, '%m/%d/%Y') AS death_date,
    CAST(IF(Age = '', 'Unknown', Age) AS UNSIGNED) AS age,
	CASE WHEN age BETWEEN 0 AND 6 THEN '0-6'
		WHEN age BETWEEN 7 AND 17 THEN '7-17'
		WHEN age BETWEEN 18 AND 30 THEN  '18-30'
		WHEN age BETWEEN 31 AND 55 THEN '31-55'
		WHEN age BETWEEN 56 AND 65 THEN '56-65'
		ELSE '66+' END AS age_bins,    
    CASE WHEN Citizenship = '' AND Name = 'Rafaele Chereilo' THEN 'Italian' WHEN Citizenship = '' AND Name = 'Ibrahim Samih Barahmeh' THEN 'Jordanian' ELSE Citizenship END AS citizenship,
    `Event location` AS event_location,
    `Event location - District` AS event_location_district,
    `Event location - Region` AS event_location_region,
    Gender AS gender,
    CASE WHEN `Took part in the hostilities` = 'Israelis' THEN 'No' WHEN `Took part in the hostilities` = 'Object of targeted killing' THEN 'Yes' WHEN `Took part in the hostilities` = 'Yes' THEN 'Yes' WHEN `Took part in the hostilities` = 'No' THEN 'No' ELSE 'Unknown' END AS hostilities_participation, 
    IF(`Place of residence` = '', 'Unknown', `Place of residence`) AS place_of_residence,
    IF(`Place of residence - District` = '', 'Unknown', `Place of residence - District`) AS place_of_residence_district,
    IF(`Type of injury` = '', 'Unknown', `Type of injury`) AS type_of_injury,
    `Killed By` AS killed_by,
    IF(Notes = '', 'Unknown', Notes) AS notes
FROM cte;
SELECT * FROM main LIMIT 250;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------Exploratory Data Analysis---------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------
-- -----Demolitions EDA-----
----------------------------

SELECT * FROM demolitions_view LIMIT 50;

-- Find min/max dates within the dataset
SELECT MIN(demolition_date) FROM demolitions_view; -- 2006-01-04
SELECT MAX(demolition_date) FROM demolitions_view; -- 2023-09-27

-- Dispaly the chronology of demolishes by years
SELECT 
	YEAR(demolition_date) AS year, 
	SUM(buildings) AS number_of_building_demolished, 
	SUM(adults_left_homeless) AS number_of_adults_left_homeless,
	SUM(minors_left_homeless) AS number_of_minors_left_homeless
FROM demolitions_view 
GROUP BY YEAR(demolition_date)
ORDER BY 1;

-- Display the chronology of demolishes by years and months
SELECT 
	YEAR(demolition_date) AS year, 
    MONTH(demolition_date) AS month,
	SUM(buildings) AS number_of_building_demolished, 
	SUM(adults_left_homeless) AS number_of_adults_left_homeless,
	SUM(minors_left_homeless) AS number_of_minors_left_homeless
FROM demolitions_view 
GROUP BY YEAR(demolition_date), MONTH(demolition_date)
ORDER BY 1, 2;

-- Display information by district
SELECT 
	district, 
	SUM(buildings) AS number_of_building_demolished, 
	SUM(adults_left_homeless) AS number_of_adults_left_homeless,
	SUM(minors_left_homeless) AS number_of_minors_left_homeless
FROM demolitions_view 
GROUP BY district
ORDER BY 2 DESC;

-- Display structure_type distribution
SELECT 
	structure_type,
	SUM(buildings) AS number_of_building_demolished
FROM demolitions_view 
GROUP BY structure_type
ORDER BY 2 DESC;

-------------------------------
-- -----People losses EDA------
-------------------------------

SELECT * FROM main LIMIT 150;

-- Find min/max dates within the dataset
SELECT MIN(death_date) FROM main; -- 2000-09-29
SELECT MAX(death_date) FROM main; -- 2023-09-24

-- Display deaths count by years
SELECT 
	YEAR(death_date) AS year, 
	COUNT(*) AS number_of_deaths 
FROM main 
GROUP BY YEAR(death_date) 
ORDER BY 1;

-- Display deaths count by years and months
SELECT 
	YEAR(death_date) AS year, 
    MONTH(death_date) AS month,
	COUNT(*) AS number_of_deaths 
FROM main 
GROUP BY YEAR(death_date), MONTH(death_date)
ORDER BY 1, 2;

-- Display age distribution
SELECT 
	age, 
    COUNT(*) AS number_of_people
FROM main 
GROUP BY age
ORDER BY 1;

-- Make age bins and display distribution by them
SELECT 
	age_bins,
	COUNT(*) AS number_of_people
FROM main
GROUP BY age_bins
ORDER BY 1;
	
-- Display citizenship distribution
WITH cte AS (
	SELECT 
		IF(citizenship = 'Palestinian' OR citizenship = 'Israeli', citizenship, 'Foreigner') AS citizenship 
	FROM main
)
SELECT
	citizenship,
    COUNT(*) AS number_of_people
FROM cte
GROUP BY citizenship;

-- Investigate event location distribution by regions
SELECT 
	event_location_region,
    COUNT(*) AS number_of_accidents
FROM main
GROUP BY event_location_region
ORDER BY 2 DESC;

-- Investigate event location distribution by districts
SELECT 
	event_location_district,
    COUNT(*) AS number_of_accidents
FROM main
GROUP BY event_location_district
ORDER BY 2 DESC;

-- Investigate event location distribution
SELECT 
	event_location,
    COUNT(*) AS number_of_accidents
FROM main
GROUP BY event_location
ORDER BY 2 DESC;

-- Display gender distribution
SELECT 
	gender,
	COUNT(*) AS number_of_people
FROM main
WHERE gender != 'NA'
GROUP BY gender
ORDER BY 2 DESC;

-- Investigate hostilities participation distribution
SELECT 
	hostilities_participation,
	COUNT(*) AS number_of_people
FROM main
GROUP BY hostilities_participation;

-- Investigate hostilities participation distribution by citizenship
WITH cte AS (
	SELECT 
		IF(citizenship = 'Palestinian' OR citizenship = 'Israeli', citizenship, 'Foreigner') AS citizenship,
		hostilities_participation
	FROM main
)
SELECT 
	citizenship,
	hostilities_participation,
	COUNT(*) AS number_of_people
FROM cte
GROUP BY hostilities_participation, citizenship
ORDER BY 1 DESC, 2 DESC;

-- Investigate type of injuries distribution
SELECT
	type_of_injury,
    COUNT(*) 
FROM main
WHERE type_of_injury != 'Unknown'
GROUP BY type_of_injury
ORDER BY 2 DESC;

-- Investigate killed bydistribution
SELECT 
	killed_by,
    COUNT(*) AS number_of_people
FROM main
GROUP BY killed_by
ORDER BY 2 DESC;

-- Investigate killed by distribution by citizenship
WITH cte AS (
	SELECT 
		IF(citizenship = 'Palestinian' OR citizenship = 'Israeli', citizenship, 'Foreigner') AS citizenship,
        killed_by
	FROM main
)
SELECT 
	citizenship,
	killed_by,
    COUNT(*) AS number_of_people
FROM cte
GROUP BY killed_by, citizenship
ORDER BY 1 DESC, 3 DESC;