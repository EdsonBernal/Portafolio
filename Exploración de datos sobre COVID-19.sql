--- Exploración de datos sobre COVID-19
--- Portafolio Edson Bernal

-- Visualización inicial de la importación de datos
SELECT* 
FROM poblacion

SELECT*
FROM covid19

--Tabla de "Población"
--Selección de datos sin NULL y uso de tabla temporal
SELECT*
INTO #pobtot_limpia
FROM poblacion
WHERE NOT LONGITUD = 'NULL'

-- Población total por estado y promedio
SELECT NOM_ENT, SUM(POBTOT) as pobtot_edo, ROUND(AVG(POBTOT),2) as pob_prom,
	ROUND(SUM(POBFEM)/SUM(POBTOT)*100, 2) AS prop_fem, 
	ROUND(SUM(POBMAS)/SUM(POBTOT)*100, 2) AS prop_masc
FROM #pobtot_limpia
GROUP BY NOM_ENT
ORDER BY pobtot_edo DESC

-- Número total de municipios por estado
SELECT NOM_ENT, COUNT(DISTINCT(NOM_MUN)) AS total_municipios
FROM #pobtot_limpia
GROUP BY NOM_ENT 
ORDER BY total_municipios DESC


-- Tabla de "casos de COVID-19"
-- Selección de casos confirmados de COVID-19
SELECT ["FECHA_ACTUALIZACION"],["SEXO"],["ENTIDAD_RES"],["MUNICIPIO_RES"],["TIPO_PACIENTE"], ["FECHA_DEF"], ["EDAD"], ["CLASIFICACION_FINAL"],["FECHA_SINTOMAS"]
INTO #casos_covid19
FROM covid19
WHERE ["CLASIFICACION_FINAL"] <= 3

-- Promedio de edad por sexo y tipo de paciente
SELECT ["SEXO"],["TIPO_PACIENTE"], AVG(CAST(["EDAD"] AS numeric)) AS PROM_Edad
FROM #casos_covid19
GROUP BY ["SEXO"],["TIPO_PACIENTE"]

-- Casos de COVID-19 por mes
SELECT SUBSTRING(["FECHA_SINTOMAS"],2,4) AS ANO, 
	   SUBSTRING(["FECHA_SINTOMAS"],7,2) AS MES, 
	   SUBSTRING(["FECHA_SINTOMAS"],10,2) AS DIA,
["FECHA_ACTUALIZACION"]
INTO #casos_covid19_2022
FROM #casos_covid19

SELECT MES, COUNT(["FECHA_ACTUALIZACION"]) AS CASOS
FROM #casos_covid19_2022
GROUP BY MES
ORDER BY MES ASC


--- Cálculo de tasas de mortalidad y letalidad
--Recodificación de variable 
UPDATE #casos_covid19
SET ["FECHA_DEF"] = '1'
WHERE NOT ["FECHA_DEF"] = '"9999-99-99"'

UPDATE #casos_covid19
SET ["FECHA_DEF"] = '0'
WHERE ["FECHA_DEF"] = '"9999-99-99"'

-- Obtención de tasa de letalidad de la COVID-19 en México para el 2022
SELECT COUNT(["FECHA_DEF"]) AS DEFUNCIONES, CAST(COUNT(["FECHA_DEF"]) AS NUMERIC)/3138715 * 100 AS LETALIDAD
FROM #casos_covid19
GROUP BY ["FECHA_DEF"]


---Tasa de Mortalidad de la COVID-19 en México por estado
--Preparación de la tabla de casos COVID-19 (remplazo de carácteres y concatenación de columnas)
SELECT REPLACE(["ENTIDAD_RES"],'"','') AS ENT, REPLACE(["MUNICIPIO_RES"],'"','') AS MUN,["FECHA_DEF"] AS DEFUNCION,
	CONCAT(REPLACE(["ENTIDAD_RES"],'"',''), REPLACE(["MUNICIPIO_RES"],'"','')) AS ENT_MUN
INTO #casos_entidad
FROM #casos_covid19
ORDER BY CONCAT(REPLACE(["ENTIDAD_RES"],'"',''), REPLACE(["MUNICIPIO_RES"],'"','')) ASC

--Preparación tabla población (estandarización de variables para la futura unión y concatenación de columnas)
SELECT CAST(ENTIDAD AS nvarchar(25)) AS ENTIDAD, NOM_ENT, CAST(MUN AS nvarchar(25)) AS MUN, NOM_MUN, POBTOT
INTO #prep_pobtot
FROM #pobtot_limpia

UPDATE #prep_pobtot
SET ENTIDAD=REPLICATE('0',(2-LEN(ENTIDAD)))+ENTIDAD 
FROM #prep_pobtot

UPDATE #prep_pobtot
SET MUN=REPLICATE('0',(3-LEN(MUN)))+MUN
FROM #prep_pobtot

SELECT CONCAT(ENTIDAD,MUN) AS ENT_MUN, SUM(POBTOT) AS POB_MUN
INTO #pob_entidad
FROM #prep_pobtot
GROUP BY CONCAT(ENTIDAD,MUN)
ORDER BY CONCAT(ENTIDAD,MUN) asc

--Left Join para obtener la población total y número de defunciones por estado y municipio
SELECT #casos_entidad.ENT_MUN, COUNT(DEFUNCION) AS TOT_DEF,POB_MUN
INTO defunciones_poblacion
FROM #casos_entidad
LEFT JOIN #pob_entidad
ON #casos_entidad.ENT_MUN=#pob_entidad.ENT_MUN
WHERE NOT #casos_entidad.ENT_MUN LIKE '%999'
GROUP BY #casos_entidad.ENT_MUN, POB_MUN
ORDER BY #casos_entidad.ENT_MUN ASC

--Cálculo de tasa de mortalidad de COVID-19 por estado
SELECT ENTIDAD,NOM_ENT
INTO entidades
FROM #prep_pobtot
GROUP BY ENTIDAD,NOM_ENT
ORDER BY ENTIDAD 

SELECT SUBSTRING(ENT_MUN,1,2) AS ENT, SUM(TOT_DEF) AS DEF, SUM(POB_MUN) AS POB
INTO #defunciones_estado
FROM defunciones_poblacion
GROUP BY SUBSTRING(ENT_MUN,1,2)
ORDER BY SUBSTRING(ENT_MUN,1,2)

SELECT ENTIDAD, NOM_ENT, DEF, POB, ROUND(DEF/POB*100,2) AS TASA_MORTALIDAD
FROM entidades
RIGHT JOIN #defunciones_estado
ON entidades.ENTIDAD=#defunciones_estado.ENT
ORDER BY ENTIDAD