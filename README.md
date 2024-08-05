# CovidSQLAnalysis
Analysis of COVID-19 Deaths and Vaccination Rates using SQL





Introduction
The COVID-19 pandemic has had a profound impact on global health and economies. Understanding the patterns of infections, deaths, and vaccination rates is crucial for public health planning and response. This project analyzes the COVID-19 data from the World Health Organization (WHO) using SQL to extract meaningful insights. The analysis includes examining the number of confirmed deaths, infection rates, and vaccination coverage across different countries and continents.

Data Source
The data used in this project is sourced from the WHO COVID-19 Dashboard. The dataset contains information on the number of confirmed COVID-19 cases, deaths, and vaccination rates. The analysis is performed using SQL queries to extract, transform, and analyze the data.

Data Analysis
1. Overview of COVID-19 Data
The initial query retrieves all records from the CovidDeath table to provide an overview of the data.

``` SQL

SELECT *
FROM CovidSQLProject..CovidDeath
ORDER BY 3, 4;


```


2. Total Cases and Deaths by Location and Date
This query retrieves the total cases and deaths along with the population for each location and date, sorted by location and date.

```sql
SELECT Location, date, total_cases, total_deaths, population
FROM CovidSQLProject..CovidDeath
ORDER BY 1, 2;

```


3. Death Percentage for the United States
To understand the likelihood of dying if one contracts COVID-19 in the United States, this query calculates the death percentage.

```sql
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidSQLProject..CovidDeath
WHERE total_cases != 0
AND location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1, 2;

```

4. Infection Rate Compared to Population
This query calculates the percentage of the population infected with COVID-19 in the United States.


```sql

SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidSQLProject..CovidDeath
WHERE location LIKE '%states%'
ORDER BY 1, 2;

```


5. Countries with the Highest Infection Rate
This query identifies countries with the highest infection rates compared to their population.

```sql

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidSQLProject..CovidDeath
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


```


6. Countries with the Highest Death Count
To determine which countries have the highest death counts, this query retrieves the maximum number of deaths per country.


```sql

SELECT Location, MAX(CAST(total_deaths AS INT)) AS HighestDeathsCount
FROM CovidSQLProject..CovidDeath
GROUP BY Location
ORDER BY HighestDeathsCount DESC;

```


7. Continents with the Highest Death Count
This query shows continents with the highest death counts per population.


```sql

SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestDeathsCount
FROM CovidSQLProject..CovidDeath
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY HighestDeathsCount DESC;

```


8. Global Numbers
To get a global perspective, this query sums up the total cases and deaths and calculates the global death percentage.

```sql

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidSQLProject..CovidDeath
WHERE continent IS NOT NULL AND new_cases != 0
GROUP BY date
ORDER BY 1, 2;

```

9. Vaccination Rates
This query shows the percentage of the population that has received at least one COVID-19 vaccine dose.


```sql

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.Location ORDER BY d.location, d.Date) AS RollingPeopleVaccinated
FROM CovidSQLProject..CovidDeath d
JOIN CovidSQLProject..CovidVaccination v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;

```


10. Using CTE for Vaccination Calculation
A Common Table Expression (CTE) is used to perform calculations on the partitioned data.

```sql

WITH popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.Location ORDER BY d.location, d.Date) AS RollingPeopleVaccinated
FROM CovidSQLProject..CovidDeath d
JOIN CovidSQLProject..CovidVaccination v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS percentage
FROM popvsvac;

```


11. Using Temporary Table for Vaccination Calculation
This query demonstrates the use of a temporary table to perform calculations on partitioned data.

```sql

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.Location ORDER BY d.location, d.Date) AS RollingPeopleVaccinated
FROM CovidSQLProject..CovidDeath d
JOIN CovidSQLProject..CovidVaccination v
ON d.location = v.location
AND d.date = v.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated;

```


12. Creating a View for Vaccination Data
This view stores the calculated data for later visualizations.

```sql

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    d.continent, 
    d.location, 
    d.date, 
    d.population, 
    ISNULL(v.new_vaccinations, 0) AS new_vaccinations,
    SUM(CONVERT(BIGINT, ISNULL(v.new_vaccinations, 0))) 
    OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM 
    CovidSQLProject..CovidDeath d
JOIN 
    CovidSQLProject..CovidVaccination v
ON 
    d.location = v.location
    AND d.date = v.date
WHERE 
    d.continent IS NOT NULL;

```

Discussion
The analysis provided valuable insights into the impact of COVID-19 across different regions. Key findings include:

The United States had significant variations in death percentages, highlighting the importance of healthcare infrastructure and response.
Infection rates relative to population showed which countries were most affected, emphasizing the need for targeted interventions.
Vaccination data analysis revealed disparities in vaccination coverage, underlining the importance of equitable vaccine distribution.
These insights can aid policymakers in making informed decisions to combat the pandemic effectively and ensure better preparedness for future health crises.























































































































