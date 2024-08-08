# CovidSQLAnalysis

Analysis of COVID-19 Deaths and Vaccination Rates using SQL and Tableau



## Table of Contents

1. [Introduction](#introduction)
2. [Data Source](#data-source)
3. [Methodology](#methodology)
4. [Visualizations](#visualizations)
5. [Dashboard](#dashboard)
6. [Discussion](#discussion)
7. [Conclusion](#Conclusion)





## Introduction

The COVID-19 pandemic has had a profound impact on global health, economies, and daily life. Understanding the spread and impact of the virus through data analysis and visualization helps in gaining insights into the pandemic's trends and patterns. This project involves analyzing the COVID-19 data from the World Health Organization (WHO) and Our World in Data using SQL to extract meaningful insights, followed by the creation of visualizations in Tableau. The project focuses on key metrics such as total cases, deaths, death rates, infection percentages, and vaccination coverage across different countries and continents.

## Data Source

The data used in this project is sourced from two key datasets:

**World Health Organization (WHO) COVID-19 Dashboard:** This dataset contains information on confirmed COVID-19 cases, deaths, and vaccination rates globally.

**Our World in Data COVID-19 Dataset:** This comprehensive dataset includes information on COVID-19 cases, deaths, testing, and other related metrics across different countries and regions.

**Data Link**

https://ourworldindata.org/covid-deaths

## Methodology

**SQL Analysis:** Several SQL queries were performed on the WHO COVID-19 dataset to analyze total cases, deaths, death percentages, infection rates, and vaccination coverage. The results of these queries were saved as Excel files for further analysis.

**Tableau Visualizations:** The Excel files generated from SQL queries were imported into Tableau to create visualizations, focusing on global and regional impacts of the pandemic.


**1. Overview of COVID-19 Data**

The initial query retrieves all records from the CovidDeath table to provide an overview of the data.

``` SQL

SELECT *
FROM CovidSQLProject..CovidDeath
ORDER BY 3, 4;


```


**2. Total Cases and Deaths by Location and Date**

This query retrieves the total cases and deaths along with the population for each location and date, sorted by location and date.

```sql
SELECT Location, date, total_cases, total_deaths, population
FROM CovidSQLProject..CovidDeath
ORDER BY 1, 2;

```


**3. Death Percentage for the United States**

To understand the likelihood of dying if one contracts COVID-19 in the United States, this query calculates the death percentage.

```sql
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidSQLProject..CovidDeath
WHERE total_cases != 0
AND location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1, 2;

```

**4. Infection Rate Compared to Population**

This query calculates the percentage of the population infected with COVID-19 in the United States.


```sql

SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidSQLProject..CovidDeath
WHERE location LIKE '%states%'
ORDER BY 1, 2;

```


**5. Countries with the Highest Infection Rate**

This query identifies countries with the highest infection rates compared to their population.

```sql

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidSQLProject..CovidDeath
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


```


**6. Countries with the Highest Death Count**

To determine which countries have the highest death counts, this query retrieves the maximum number of deaths per country.


```sql

SELECT Location, MAX(CAST(total_deaths AS INT)) AS HighestDeathsCount
FROM CovidSQLProject..CovidDeath
GROUP BY Location
ORDER BY HighestDeathsCount DESC;

```


**7. Continents with the Highest Death Count**

This query shows continents with the highest death counts per population.


```sql

SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestDeathsCount
FROM CovidSQLProject..CovidDeath
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY HighestDeathsCount DESC;

```


**8. Global Numbers**

To get a global perspective, this query sums up the total cases and deaths and calculates the global death percentage.

```sql

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidSQLProject..CovidDeath
WHERE continent IS NOT NULL AND new_cases != 0
GROUP BY date
ORDER BY 1, 2;

```

**9. Vaccination Rates**

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


**10. Using CTE for Vaccination Calculation**

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


**11. Using Temporary Table for Vaccination Calculation**

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


**12. Creating a View for Vaccination Data**

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

## Visualizations


**Global Numbers Table:** This table summarizes global statistics, including total cases, total deaths, and the death percentage. It provides a concise overview of the pandemic's impact on a global scale.

**Bar Chart of Total Death Counts per Continent:** A bar chart displays the total death counts for each continent, highlighting the regions most affected by the pandemic. This visualization helps to understand the geographic distribution of COVID-19 deaths.

```sql


Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidSQLProject..CovidDeath
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

```

<img width="421" alt="image" src="https://github.com/user-attachments/assets/f8b81717-c1ec-405b-8c7c-cf040a67bc1d">



**Geographical Chart of Percent of Population Infected per Country:** This map-based visualization shows the percentage of the population infected with COVID-19 in each country. It uses color coding to represent infection rates, making it easy to identify hotspots and compare infection rates across countries.

```sql

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidSQLProject..CovidDeath
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

```
<img width="539" alt="image" src="https://github.com/user-attachments/assets/6deb83a2-5cdb-4df4-9837-4718779cbe98">


**Line Chart of Percent of Population Infected with Forecasting Analysis:** This line chart compares the infection rates over time for selected countries (US, France, Italy, UK, China, and India). It includes forecasting analysis to predict future trends, providing valuable insights into the pandemic's trajectory.


```sql

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidSQLProject..CovidDeath
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc
```

<img width="533" alt="image" src="https://github.com/user-attachments/assets/5e9d97ab-98c8-4806-a199-cf80e01a5cec">


## Dashboard

A comprehensive dashboard was created in Tableau, integrating all four visualizations. The dashboard allows for interactive exploration of the data, enabling users to filter, zoom, and drill down into specific metrics. This holistic view of the data provides a deeper understanding of the global and regional impacts of COVID-19.

### Dashboard Components:

**Global Numbers Table:** Summarizes global statistics.

**Bar Chart of Total Death Counts per Continent:** Visualizes the death toll across continents.

**Geographical Chart of Percent of Population Infected per Country:** Maps infection rates globally.

**Line Chart of Percent of Population Infected with Forecasting Analysis:** Tracks and forecasts infection rates.


## Discussion

The analysis provided valuable insights into the impact of COVID-19 across different regions:

**Global Severity:** The Global Numbers Table highlights the severity of the pandemic, with millions of cases and a significant number of deaths worldwide.

**Regional Differences:** The Bar Chart of Total Death Counts per Continent reveals significant regional disparities, with Europe and the Americas experiencing higher death tolls.

**Hotspots Identification:** The Geographical Chart of Percent of Population Infected per Country shows varying infection rates, helping to identify and compare hotspots across countries.

**Predictive Analysis:** The Line Chart with Forecasting Analysis provides predictive insights, aiding policymakers and health officials in planning and response strategies.


## Conclusion

This project demonstrates the power of combining SQL for data extraction and Tableau for data visualization to analyze and communicate complex data related to the COVID-19 pandemic. The integration of SQL queries with Tableau visualizations provides a comprehensive approach to understanding the spread and impact of the virus. The insights gained from this project can help inform public health decisions and response strategies, contributing to better preparedness for current and future health crises.
























































































































