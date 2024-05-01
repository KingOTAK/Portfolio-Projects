SELECT * 
FROM portfolio_project.nashville_housing;

-- standardise saledate by taking of the time 

ALTER TABLE portfolio_project.nashville_housing
CHANGE COLUMN SaleDate SaleDate DATE NULL DEFAULT NULL;

-- POPULATE PROPERTY ADDRESS DATA

SELECT a.UniqueID, a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.propertyaddress, b.propertyaddress)
FROM portfolio_project.nashville_housing a
JOIN portfolio_project.nashville_housing b 
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.propertyaddress IS NULL;

UPDATE portfolio_project.nashville_housing a
JOIN portfolio_project.nashville_housing b 
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.propertyaddress = IFNULL(a.propertyaddress, b.propertyaddress);

SELECT 
	substring_index(owneraddress, ',', 1) as address,
	substring_index(substring_index(owneraddress, ',', -2), ',' -1) as city,
    substring_index(owneraddress, ',', -1) as state
from portfolio_project.nashville_housing;

-- change Y and N to Yes and No in soldasvacant

SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM portfolio_project.nashville_housing
GROUP BY soldasvacant
order by 1;

SELECT soldasvacant,
CASE 
	WHEN soldasvacant = 'Y' THEN 'YES'
    WHEN soldasvacant = 'N' THEN 'NO'
    ELSE soldasvacant
END
FROM portfolio_project.nashville_housing;


UPDATE portfolio_project.nashville_housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'YES'
    WHEN soldasvacant = 'N' THEN 'NO'
    ELSE soldasvacant
END;

-- REMOVE DUPLICATES

	-- check for duplicates
    
SELECT ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference, COUNT(*)
FROM portfolio_project.nashville_housing
GROUP BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
HAVING COUNT(*) > 1;

SELECT *, ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
FROM portfolio_project.nashville_housing;

WITH row_numcte AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
FROM portfolio_project.nashville_housing
)
SELECT *
FROM row_numcte
WHERE row_num > 1;

-- creat an identical table so that the changes doesnt affect the raw data

CREATE TABLE nh LIKE nashville_housing;

-- we now add the row column that will be populated to enable us locate the duplicates that will be deleted

ALTER TABLE portfolio_project.nh 
ADD COLUMN row_num INT;

-- we now insert into the the new table with the added 'row_num' column 

INSERT INTO portfolio_project.nh
SELECT *, ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) AS row_num
FROM portfolio_project.nashville_housing;

-- WE now check if the duplicates are really available in the  new table
SELECT * 
FROM portfolio_project.nh
WHERE row_num > 1;

-- we now delete the duplicates 
DELETE 
FROM portfolio_project.nh
WHERE row_num > 1;

-- check if the duplicates are deleted
SELECT * 
FROM portfolio_project.nh
WHERE row_num > 1;

