-- fixing the date
ALTER TABLE CovidDeaths 
ADD COLUMN date_temp DATE;

UPDATE CovidDeaths 
SET date_temp = STR_TO_DATE(`date`, '%m/%d/%y');

SELECT `date`, date_temp FROM CovidDeaths LIMIT 10;

ALTER TABLE CovidDeaths 
DROP COLUMN `date`, 
CHANGE date_temp `date` DATE NULL DEFAULT NULL;

-- Adding NULL values to blanks
UPDATE CovidDeaths
SET continent = NULL
WHERE continent = '';

-- Looking at CovidDeaths
SELECT *
FROM CovidDeaths
WHERE continent IS NOT null
ORDER BY 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths;

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY Location, population
ORDER BY PercentPopulationInfected desc;

-- Showing Countries with Highest Death Count per Population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT null
GROUP BY Location
ORDER BY TotalDeathCount desc;

-- BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- Weekly Global Numbers
-- new_cases and new_deaths are only entered in on Sundays, all other days are set to 0
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
AND DAYOFWEEK(date) = 1
GROUP BY date
ORDER BY 1,2;

-- Entire date range
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
AND DAYOFWEEK(date) = 1
ORDER BY 1,2;

-- Looking at CovidVaccinations
-- fixing the date
ALTER TABLE CovidVaccinations 
ADD COLUMN date_temp DATE;

UPDATE CovidVaccinations 
SET date_temp = STR_TO_DATE(`date`, '%m/%d/%y');

SELECT `date`, date_temp FROM CovidVaccinations LIMIT 10;

ALTER TABLE CovidVaccinations 
DROP COLUMN `date`, 
CHANGE date_temp `date` DATE NULL DEFAULT NULL;

-- Adding NULL values to blanks
UPDATE CovidVaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations = '';

-- Looking at Total Population vs Vaccination
SELECT *
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
    
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER by 2,3;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/dea.population)*100
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'Albania'
ORDER by 2,3;

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;