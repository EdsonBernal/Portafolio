--- Preparación y limpieza de datos sobre viviendas
--- Portafolio Edson Bernal

-- Visualización inicial de la importación de datos
SELECT*
FROM casas

---Estandarización del formato de fecha
SELECT fecha_venta, CONVERT(Date, SaleDate)
FROM casas

ALTER TABLE casas
ADD fecha_venta DATE;

UPDATE casas
SET fecha_venta = CONVERT(Date, SaleDate) 

--Remplazo de los valores "NULL" por los valores adecuados en una columna
SELECT *
FROM casas
WHERE PropertyAddress is NULL

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM casas AS A
JOIN casas AS B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM casas AS A
JOIN casas AS B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

--División de la columna que contiene la dirección en dos (ciudad y calle)
SELECT 
SUBSTRING(PropertyAddress,1, CHARINDEX (',', PropertyAddress)-1) AS direccion,
SUBSTRING(PropertyAddress,CHARINDEX (',', PropertyAddress)+1, LEN(PropertyAddress)) AS direccion
FROM casas

ALTER TABLE casas
ADD direccion_dividida Nvarchar(300)

UPDATE casas
SET direccion_dividida = SUBSTRING(PropertyAddress,1, CHARINDEX (',', PropertyAddress)-1)

ALTER TABLE casas
ADD ciudad_dividida Nvarchar(300)

UPDATE casas
SET ciudad_dividida = SUBSTRING(PropertyAddress,CHARINDEX (',', PropertyAddress)+1, LEN(PropertyAddress))

--Separación de la dirección del propietario en 3 columnas
ALTER TABLE casas
ADD direccion_propietario Nvarchar(300)

UPDATE casas
SET direccion_propietario = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

ALTER TABLE casas
ADD ciudad_propietario Nvarchar(300)

UPDATE casas
SET ciudad_propietario = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

ALTER TABLE casas
ADD estado_propietario Nvarchar(300)

UPDATE casas
SET estado_propietario = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

--Transformación de valores "N" y "Y" en "No" y "Yes"
SELECT DISTINCT(SoldAsVacant)
FROM casas

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM casas

UPDATE casas
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

--- Eliminación de duplicados y creación de tabla temporal
WITH numero_fila_rep AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) num_fila
FROM casas
)

DELETE
FROM numero_fila_rep
WHERE num_fila > 1

--- Eliminación de columnas no necesarias
SELECT *
FROM casas

ALTER TABLE casas
DROP COLUMN OwnerAddress,TaxDistrict, PropertyAddress, SaleDate
