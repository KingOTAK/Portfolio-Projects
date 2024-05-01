SELECT * 
FROM portfolio_project.layoffs;

-- 1. remove duplicates if any
-- 2. standardise data
-- 3. null values or blank values
-- 4. remove any columns

-- 1. REMOVING DUPLICATES
-- to remove the duplicates we stage the table
-- we do this so we dont affect te raw data

CREATE TABLE layoffs_staging 
LIKE portfolio_project.layoffs;

INSERT INTO portfolio_project.layoffs_staging
SELECT * 
FROM portfolio_project.layoffs;

-- we number the rows that have te same columns
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM portfolio_project.layoffs_staging;

-- we use cte to select the rows that has duplicates
WITH lsduplicate AS
(SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM portfolio_project.layoffs_staging
)
SELECT *
FROM lsduplicate
WHERE row_num > 1;

-- add the row_number to the staged table
ALTER TABLE portfolio_project.layoffs_staging
ADD COLUMN row_num int;

-- check if the row has been added
SELECT *
FROM portfolio_project.layoffs_staging;

-- insert the row numbering into the table
INSERT INTO portfolio_project.layoffs_staging
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM portfolio_project.layoffs;

-- here i can truncate the staged table and add all columns with the numbered row column
TRUNCATE portfolio_project.layoffs_staging;

INSERT INTO portfolio_project.layoffs_staging
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM portfolio_project.layoffs;

-- or create a second staged table and now fill it all columns and the numbered row
CREATE TABLE layoffs_staging2 
LIKE portfolio_project.layoffs_staging;

INSERT INTO portfolio_project.layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM portfolio_project.layoffs;

-- check for the dupicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- delete the duplicates (rows with greater than 1)
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- check if the duplicates are deleted
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. STANDARDISE DATA
-- check for spaces before and after the company list
SELECT company, TRIM(company)
FROM portfolio_project.layoffs_staging2;

UPDATE portfolio_project.layoffs_staging2
SET company = TRIM(company);

-- change all indsutry with crypto in their name to 'crypto' in industries

-- check for the industries with crypto in their name
SELECT DISTINCT(industry)
FROM portfolio_project.layoffs_staging2
WHERE industry LIKE 'crypto%';

UPDATE portfolio_project.layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

-- correct the name of the united states in country
SELECT DISTINCT(country)
FROM portfolio_project.layoffs_staging2
ORDER BY 1;

SELECT country, TRIM(TRAILING '.' FROM country)
FROM portfolio_project.layoffs_staging2
WHERE country LIKE 'United States.';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE industry LIKE 'United States.';

-- converting te date from string to date format
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM portfolio_project.layoffs_staging2;

UPDATE portfolio_project.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM portfolio_project.layoffs_staging2;

ALTER TABLE portfolio_project.layoffs_staging2
MODIFY COLUMN `date` DATE;

-- REMOVE BLANKS AND NULL 

SELECT *
FROM portfolio_project.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM portfolio_project.layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM portfolio_project.layoffs_staging2
WHERE company = 'airbnb';

-- join the table to itself where the indusrty is blank/null on t1 and not on t2
SELECT *
FROM portfolio_project.layoffs_staging2 t1
JOIN portfolio_project.layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL OR t2.industry <> '');

SELECT t1.industry, t2.industry
FROM portfolio_project.layoffs_staging2 t1
JOIN portfolio_project.layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL OR t2.industry <> '');

UPDATE portfolio_project.layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE portfolio_project.layoffs_staging2 t1
JOIN portfolio_project.layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL OR t2.industry <> '');

-- delete the rows without the total_laid_off and percenage_laid_off since we dont have the data to populate them

DELETE
FROM portfolio_project.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- check if indeed they are deleted
SELECT *
FROM portfolio_project.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM portfolio_project.layoffs_staging2;

-- dont need the row_num column so we are going to delete it
ALTER TABLE portfolio_project.layoffs_staging2
DROP COLUMN row_num;



