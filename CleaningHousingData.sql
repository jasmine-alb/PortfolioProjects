/* 
Cleaning Data in SQL Queries 

Queries done in MySQL

*/

SELECT *
FROM NashvilleHousingData.housingdata;
-------------------------------------------------------------

-- Standarize Date Format

SELECT
    SaleDate,
    STR_TO_DATE(SaleDate, '%M %e, %Y') AS converted_date
FROM NashvilleHousingData.housingdata;

ALTER TABLE NashvilleHousingData.housingdata
Add SaleDateConverted Date;

UPDATE NashvilleHousingData.housingdata
SET SaleDateConverted = (STR_TO_DATE(SaleDate, '%M %e, %Y'));

	-- Now for organization, I will drop the old column, and rename the new column we just created 
    
    ALTER TABLE NashvilleHousingData.housingdata
    DROP COLUMN SaleDate;
    
    ALTER TABLE NashvilleHousingData.housingdata
    RENAME COLUMN SaleDateConverted TO SaleDate;




-------------------------------------------------------------

-- Populate Property Address data

Select *
FROM NashvilleHousingData.housingdata
WHERE PropertyAddress IS NULL;

	-- There are null values in this dataset, so let's investigate how we can find this data
    
	SELECT*
    FROM NashvilleHousingData.housingdata
    WHERE ParcelID = "025 07 0 031.00" 
    ORDER BY PropertyAddress

    -- ParcelID remains consistent for each address. When the address is NULL, we can use the corresponding ParcelID to update the table with the correct address.

	UPDATE NashvilleHousingData.housingdata a,
		NashvilleHousingData.housingdata b 
	SET 
		b.propertyaddress = a.propertyaddress
	WHERE
		b.propertyaddress IS NULL
			AND b.parcelid = a.parcelid
			AND a.propertyaddress IS NOT NULL;


-------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

SELECT
	substring_index(PropertyAddress, ',', 1) AS streetname,
    TRIM(substring_index(PropertyAddress, ',', -1)) AS city
FROM NashvilleHousingData.housingdata

	-- Now I need to create two new columns so I can add this data in
    
    ALTER TABLE NashvilleHousingData.housingdata
    ADD COLUMN PropertySplitAddress VARCHAR(255),
    ADD COLUMN PropertySplitCity VARCHAR(255);
    
    -- Adding the split address data into table 
    
    UPDATE NashvilleHousingData.housingdata
    SET 
		PropertySplitAddress = substring_index(PropertyAddress, ',', 1),
        PropertySplitCity = TRIM(substring_index(PropertyAddress, ',', -1));
   

-- Now I'll do the same with the OwnderAddress Column
SELECT 
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
	TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS City,
	TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM NashvilleHousingData.housingdata

	-- Adding the new columns to hold this data 
    ALTER TABLE NashvilleHousingData.housingdata
    ADD COLUMN OwnerSplitAddress VARCHAR(255),
    ADD COLUMN OwnerSplitCity VARCHAR(255),
    ADD COLUMN OwnerSplitState VARCHAR(255);
    
    -- Adding Split Owner Address into the table 
    UPDATE NashvilleHousingData.housingdata
    SET 
		OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
        OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)),
        OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));



-------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" Field 

SELECT DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM NashvilleHousingData.housingdata
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END 
FROM NashvilleHousingData.housingdata;


UPDATE NashvilleHousingData.housingdata
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;



-------------------------------------------------------------------
-- REMOVE DUPLICATES


-- To identify duplicates I will use the ROW_NUMBER function
SELECT 
    ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference,
    UniqueID,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID
    ) AS row_num
FROM NashvilleHousingData.housingdata
order by row_num DESC;

	-- From this query I see that there are several duplicate entires, so let's remove them from the table by creating a temporary table 
	
    CREATE TEMPORARY TABLE temp_housingdata AS
	SELECT 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference,
		UniqueID,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			ORDER BY UniqueID
		) AS row_num
	FROM 
		housingdata

	DELETE FROM temp_housingdata
	WHERE row_num > 1;
    
    SELECT*
    FROM temp_housingdata
    ORDER BY row_num DESC; -- this query verifies that all duplicate data has been deleted from the temporary table 
    

---------------------------------------------------------------
-- Delete Unused Columns 

CREATE temporary Table temp_housingdata2 AS -- creating temp table so I don't delete columns from the original dataset 
	SELECT *
    FROM housingdata; 
    
SELECT* FROM temp_housingdata2

ALTER TABLE temp_housingdata2
	DROP COLUMN TaxDistrict,
	DROP COLUMN PropertyAddress,
	DROP COLUMN OwnerAddress;

    

