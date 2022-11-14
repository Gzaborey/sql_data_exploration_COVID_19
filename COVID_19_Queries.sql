-- Looking at all the Data 

SELECT * 
FROM PortfolioProject_1.dbo.CovidDeaths
WHERE continent IS NOT NULL

-- Select Data that will be used.

SELECT Location, date, total_cases, new_cases, total_deaths, population	
FROM PortfolioProject_1.dbo.CovidDeaths
ORDER BY 1, 2

-- Looking for NULL values.

SELECT COUNT(*)-COUNT(Location) AS NULL_Location, COUNT(*)-COUNT(date) AS NULL_date,
		COUNT(*)-COUNT(total_cases) AS NULL_total_cases, COUNT(*)-COUNT(new_cases) AS NULL_new_cases, 
		COUNT(*)-COUNT(total_deaths) AS NULL_total_deaths, COUNT(*)-COUNT(population) AS NULL_population	
FROM PortfolioProject_1.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Looking at total cases vs total deaths i.e. death percentage of COVID 19

SELECT Location, date, total_cases, total_deaths, 
CASE 
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases) * 100
END AS death_percentage
FROM PortfolioProject_1..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2

-- Looking at a death percentages of COVID 19 in Ukraine

SELECT Location, date, total_cases, total_deaths, 
CASE 
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases) * 100
END AS death_percentage
FROM PortfolioProject_1..CovidDeaths
WHERE Location = 'Ukraine'
ORDER BY 1,2

-- Looking at a percentage of infected population by COVID 19

SELECT Location, date, total_cases, population, 
CASE 
	WHEN population = 0 THEN 0
	ELSE (total_cases/population) * 100
END AS infection_rate
FROM PortfolioProject_1..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2

-- Looking at a percentage of infected population by COVID 19 in Ukraine

SELECT Location, date, total_cases, population, 
CASE 
	WHEN population = 0 THEN 0
	ELSE (total_cases/population) * 100
END AS infection_rate
FROM PortfolioProject_1..CovidDeaths
WHERE Location = 'Ukraine'
ORDER BY 1,2

--Peak infection rates in each country during pandemic

SELECT Location,
MAX(CASE 
	WHEN population = 0 THEN 0
	ELSE (total_cases/population) * 100
END) AS infection_rate
FROM PortfolioProject_1..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC

--Peak infection rate in Ukraine during pandemic

SELECT Location,
MAX(CASE 
	WHEN population = 0 THEN 0
	ELSE (total_cases/population) * 100
END) AS infection_rate
FROM PortfolioProject_1..CovidDeaths
WHERE Location = 'Ukraine'
GROUP BY Location
ORDER BY 2 DESC

-- Death toll (in percents) in each country

SELECT Location,
MAX(CASE 
	WHEN population = 0 THEN 0
	ELSE (total_deaths/population) * 100
END) AS percent_died
FROM PortfolioProject_1..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC

-- Death toll (in percents) in Ukraine

SELECT Location,
MAX(CASE 
	WHEN population = 0 THEN 0
	ELSE (total_deaths/population) * 100
END) AS percent_died
FROM PortfolioProject_1..CovidDeaths
WHERE Location = 'Ukraine'
GROUP BY Location
ORDER BY 2 DESC


SELECT Location, date, total_cases, MAX(total_cases) OVER (PARTITION BY Location) AS max_infected 
FROM PortfolioProject_1..CovidDeaths
GROUP BY Location, date, total_cases
ORDER BY 3 DESC

SELECT Location, total_cases,
MAX(CASE 
	WHEN population = 0 THEN 0
	ELSE (total_cases/population) * 100
END) AS infection_rate
FROM PortfolioProject_1..CovidDeaths
GROUP BY Location, total_cases
ORDER BY 2 DESC

-- Analysing continents

-- Global indicators

SELECT date, SUM(new_cases) AS cum_new_cases, SUM(CAST(new_deaths as INT)) AS cum_new_deaths,
		SUM(CAST(new_deaths as INT))/SUM(new_cases) * 100 AS death_ratio
FROM PortfolioProject_1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC

-- Creating view for global indicators

CREATE VIEW GlobalIndicators
AS 
SELECT date, SUM(new_cases) AS cum_new_cases, SUM(CAST(new_deaths as INT)) AS cum_new_deaths,
		SUM(CAST(new_deaths as INT))/SUM(new_cases) * 100 AS death_ratio
FROM PortfolioProject_1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date


-- Cumulative sum of vacinated people per country

SELECT d.continent, d.location, d.date, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.date) AS cum_vaccinations_per_country
FROM PortfolioProject_1..CovidDeaths AS d
	JOIN PortfolioProject_1..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
	WHERE d.continent IS NOT NULL
	ORDER BY location, date


-- Use CTE

WITH cum_vac (population, continent, location, date, new_vaccinations, cum_vaccinations_per_country)
AS
(
SELECT d.population, d.continent, d.location, d.date, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.date) AS cum_vaccinations_per_country
FROM PortfolioProject_1..CovidDeaths AS d
	JOIN PortfolioProject_1..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
	WHERE d.continent IS NOT NULL
)
SELECT *, (cum_vaccinations_per_country/population) * 100 AS cum_percent_vaccinated
FROM cum_vac


-- Temp table

CREATE TABLE #CumPercentPopulationVaccinated
(
population numeric,
continent nvarchar(255),
location nvarchar(255),
date datetime,
new_vaccinations numeric, 
cum_vaccinations_per_country numeric
)


INSERT INTO #CumPercentPopulationVaccinated (population, continent, location, date, new_vaccinations, cum_vaccinations_per_country)
SELECT d.population, d.continent, d.location, d.date, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.date) AS cum_vaccinations_per_country
FROM PortfolioProject_1..CovidDeaths AS d
	JOIN PortfolioProject_1..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
	WHERE d.continent IS NOT NULL


-- Creating view for future visualisation

CREATE VIEW CumPercentVaccinated 
AS SELECT d.population, d.continent, d.location, d.date, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.date) AS cum_vaccinations_per_country
		FROM PortfolioProject_1..CovidDeaths AS d
	JOIN PortfolioProject_1..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
	WHERE d.continent IS NOT NULL
