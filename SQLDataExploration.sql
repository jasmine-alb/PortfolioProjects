/*Covid 19 Data Exploration Project

In this project I will be doing some data exploration of COVID-19 data. My goal is to manage, manipulate, and do some baseline analysis of this data using my SQL skills. 

Skills used: Joins, CTEs, Creat Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Completed in BigQueryConsole 
This dataset spans between 01-01-2020 through 04-03-2021

*/


SELECT*
FROM `sql-data-exploration-434719.CovidData.deaths`
ORDER BY 3,4;


-- Select Data that we are going to be starting with from Deaths table
SELECT
  location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM `sql-data-exploration-434719.CovidData.deaths`
ORDER BY 1,2;


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country 
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS DeathPercentage
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE location = 'United States'
ORDER BY 1,2;

-- Total Cases vs Population in the United States
-- Shows what percentage of population got infected with Covid in the US
SELECT
  location,
  date,
  population,
  total_cases,
  (total_cases/population)*100 AS PercentPopulationInfected
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE location = 'United States'
ORDER BY 1,2;

-- Looking at Average Contraction Rate by Location
-- Identifies the top 10 locations with the highest average contraction rate (percentage of cases relative to population) and highest cumulative total cases. 
SELECT
  location,
  SUM(new_cases) AS Total_cases_cumulative,
  population,
  AVG((total_cases/population)*100) AS AverageContractionRate
FROM `sql-data-exploration-434719.CovidData.deaths`
GROUP BY location, population
ORDER BY AverageContractionRate DESC, Total_cases_cumulative DESC, location
LIMIT 10;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT
  location,
  population,
  MAX(total_cases) AS HighestInfectionCount,
  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM `sql-data-exploration-434719.CovidData.deaths`
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC; 



-- Showing Countries with Highest Death Count Per Population 
SELECT
  location,
  MAX(total_deaths) AS TotalDeathCount
FROM `sql-data-exploration-434719.CovidData.deaths`
GROUP BY location
ORDER BY TotalDeathCount DESC; 
  -- After running the query, I noticed that the location column includes data for continents, which we do not want to include in our calculations. This skews the results, as the data for continents affects the accuracy of our analysis at a more granular level. 



-- Let's rexplore the original data set to see how I can address this 

SELECT *
FROM `sql-data-exploration-434719.CovidData.deaths`
ORDER BY 3,4; 
-- In the continent column, there are several NULL values. When the continent column contains NULL values, the location column includes the continent name. This inconsistency will impact the accuracy of the results. 



-- Let's fix this by cleaning NULL values 
SELECT *
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL -- We will add this to every script moving forward 
ORDER BY 3,4; 


-- With cleaned data, Showing Countries with Highest Death Count Per Population 
SELECT
  location,
  MAX(total_deaths) AS TotalDeathCount
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC; 



-- LET'S BREAK THINGS DOWN BY CONTINENT 

--Showing Continent with the Highest Death Count Per Population 
SELECT
  continent,
  MAX(total_deaths) AS TotalDeathCount
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC; 



-- GLOBAL NUMBERS

-- Global Total Cases per Day 
SELECT
  date,
  SUM(new_cases) AS GlobalTotalDeaths,
  --total_deaths,
  --(total_deaths/total_cases)*100 AS DeathPercentage
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2 DESC;

-- GLOBAL NUMBERS per Day
SELECT
  date,
  SUM(new_cases) AS TotalCases,
  SUM(new_deaths) AS TotalDeaths,
  SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2 DESC;




-- Now let's look at the total global numbers
SELECT
  SUM(new_cases) AS GlobalTotalCases,
  SUM(new_deaths) AS GlobalTotalDeaths,
  SUM(new_deaths)/SUM(new_cases) AS GlobalDeathPercentage
  --total_deaths,
  --(total_deaths/total_cases)*100 AS DeathPercentage
FROM `sql-data-exploration-434719.CovidData.deaths`
WHERE continent IS NOT NULL 
ORDER BY 1,2;




-- Now let's explore some data from the Covid Vaccinations table 
SELECT*
FROM `sql-data-exploration-434719.CovidData.vaccinations`
ORDER BY 3,4;



-- Let's join these two tables together and get an overview of this data 
SELECT*
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date;

-- Total Population vs Vaccinations  
-- Shows Percentage of Population that has received at least one Covid Vaccine 

SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations AS new_vaccinations_per_day,
  SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Let's create a CTE to perform Calculation on Partition By in previous query  

WITH PopvsVac
  AS (
  SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations AS new_vaccinations_per_day,
  SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,
  (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM PopvsVac;
  


-- Let's now do this but by creating a Table instead of a CTE

DROP TABLE IF EXISTS `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated`;
CREATE TABLE `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated`
(
  Continent STRING,
  location STRING,
  date datetime,
  population NUMERIC,
  new_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

-- Insert data into the table 
INSERT INTO `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated`
  SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations AS new_vaccinations_per_day,
  SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
  (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated`;


-- Another way to create a table if needed 
DROP TABLE IF EXISTS `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated`;
CREATE TABLE `sql-data-exploration-434719.CovidData.PercentPopulationVaccinated` AS
  SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations AS new_vaccinations_per_day,
  SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



-- Creating View to store data for later visualizations 

CREATE VIEW `sql-data-exploration-434719.CovidData.ViewPercentPopulationVaccinated`AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations AS new_vaccinations_per_day,
  SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM `sql-data-exploration-434719.CovidData.deaths` AS dea
JOIN `sql-data-exploration-434719.CovidData.vaccinations` AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;


