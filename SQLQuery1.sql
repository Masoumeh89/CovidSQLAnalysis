select *
from CovidSQLProject..CovidDeath
order by 3,4


select Location, date, total_cases, total_deaths, population
from CovidSQLProject..CovidDeath
order by 1,2


-- looking at total cases vs total deaths 
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidSQLProject..CovidDeath
where total_cases != 0
and location like '%states%'
and continent is not null 
order by 1,2




-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidSQLProject..CovidDeath
Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidSQLProject..CovidDeath
Group by Location, Population
order by PercentPopulationInfected desc




-- Countries with Highest Death Count per Population

Select Location,  MAX(cast(total_deaths as int)) as HighestDeathsCount
From CovidSQLProject..CovidDeath
group by location
order by HighestDeathsCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as HighestDeathsCount
From CovidSQLProject..CovidDeath
Where continent is not null 
group by continent
order by HighestDeathsCount desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidSQLProject..CovidDeath
where continent is not null and new_cases != 0
Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(bigint,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/d.population)*100

from CovidSQLProject..CovidDeath d
Join CovidSQLProject..CovidVaccination v
on d.location = v.location
and d.date = v.date
where d.continent is not null
order by 2,3



-- Using CTE to perform Calculation on Partition By in previous query



with popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as (

Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(bigint,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
from CovidSQLProject..CovidDeath d
Join CovidSQLProject..CovidVaccination v
on d.location = v.location
and d.date = v.date
where d.continent is not null
)

select *, (RollingPeopleVaccinated/population)*100 as percentage
from popvsvac


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(bigint,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated

From CovidSQLProject..CovidDeath d
Join CovidSQLProject..CovidVaccination v
	On d.location = v.location
	and d.date = v.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    d.continent, 
    d.location, 
    d.date, 
    d.population, 
    ISNULL(v.new_vaccinations, 0) AS new_vaccinations,
    SUM(CONVERT(bigint, ISNULL(v.new_vaccinations, 0))) 
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
