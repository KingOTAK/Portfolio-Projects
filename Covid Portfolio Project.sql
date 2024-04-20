SELECT * 
FROM portfolio_project.owid_covid_vac
order by 3, 4;

SELECT * 
FROM portfolio_project.owid_covid_deaths
order by 3, 4;

-- Select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from portfolio_project.owid_covid_deaths
order by 1, 2;

-- total cases vs total deaths
-- shows likelihood of dienng if you contracr covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as deathpercentage
from portfolio_project.owid_covid_deaths
where location like '%states%'
order by 1, 2;

-- look at the total cases vs population;

select location, date, total_cases, population, (total_cases/population) * 100 as casepercentage
from portfolio_project.owid_covid_deaths
where location like '%states%'
order by 1, 2;

-- countries with the highest infection rate comared to population

SELECT location, population, MAX(total_cases) as higestinfectioncount,  (MAX(total_cases)/population) * 100 as percentageinfected
from portfolio_project.owid_covid_deaths
group by location, population
order by percentageinfected desc;

-- show countries with the highest deatH count

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) as totaldeathcount
from portfolio_project.covdeath
group by location
order by MAX(CAST(total_deaths AS UNSIGNED)) DESC;

-- NOTE cast is used to convert the  the datatype
-- you do this when desc or asc order is not in order as mixed

-- lets break things down by continent

-- TOTAL DEATH COUNT PER CONTINENT,this is because of how the data is arranged

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS totaldeathcount
FROM portfolio_project.owid_covid_deaths
WHERE continent IS NULL OR continent = ''
GROUP BY location
ORDER BY totaldeathcount DESC;

-- continent wit highest death count


SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS totaldeathcount
FROM portfolio_project.owid_covid_deaths
GROUP BY continent
ORDER BY totaldeathcount DESC;

-- GOLBAL NUMBERS
-- percentage of those who died after being infected\

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases)) * 100 as deathpercentage
FROM portfolio_project.owid_covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- WORLD TOTAL CAESES AGAINST TOTAL DEATHS

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases)) * 100 as deathpercentage
FROM portfolio_project.owid_covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1;

SELECT *
FROM portfolio_project.owid_covid_deaths dea
JOIN portfolio_project.owid_covid_vac vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
    
-- total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date) AS rolllingpeoplevaccinated
FROM portfolio_project.owid_covid_deaths dea
JOIN portfolio_project.owid_covid_vac vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3;

-- USE CTE

WITH popsvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date) AS rolllingpeoplevaccinated
FROM portfolio_project.owid_covid_deaths dea
JOIN portfolio_project.owid_covid_vac vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3)
SELECT *, (rollingpeoplevaccinated/population) * 100
FROM popsvsvac;

-- USE TEMP TABLE;

DROP TEMPORARY TABLE IF EXISTS percentagepopulationvaccinated;
CREATE TEMPORARY TABLE percentagepopulationvaccinated
(
continent varchar(100), 
location varchar(100), 
date datetime, 
population TEXT, 
new_vaccinations TEXT, 
rollingpeoplevaccinated TEXT
);

INSERT INTO percentagepopulationvaccinated
(continent, location, date , population, new_vaccinations, rollingpeoplevaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date) AS rolllingpeoplevaccinated
FROM portfolio_project.owid_covid_deaths dea
JOIN portfolio_project.owid_covid_vac vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3;

SELECT *, (rollingpeoplevaccinated/population) * 100
FROM percentagepopulationvaccinated;

-- CREATE A VIEW

CREATE VIEW popsvsvac AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER(PARTITION BY location ORDER BY dea.location, dea.date) AS rolllingpeoplevaccinated
FROM portfolio_project.owid_covid_deaths dea
JOIN portfolio_project.owid_covid_vac vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3;