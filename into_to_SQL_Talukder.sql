/* Creating a view called "forestation" */
CREATE VIEW forestation
AS
	SELECT f.country_code country_code, 
    	   f.country_name country, 				
           f.forest_area_sqkm forest_area,
           l.total_area_sq_mi * 2.59 total_land_area_sqkm,
		   (f.forest_area_sqkm*100) / (l.total_area_sq_mi*2.59) forest_area_percentage ,
           f.year,
           r.region, 
           r.income_group 
	FROM forest_area f
    JOIN land_area l
    	ON f.year = l.year AND f.country_code =l.country_code
    JOIN regions r
    	ON f.country_code = r.country_code;

/* Total forest area in 1990*/

SELECT  fv.forest_area
		FROM forestation fv
			WHERE fv.year = 1990 AND fv.region = 'World';

/* Total forest area in 2016*/
SELECT  fv.forest_area
		FROM forestation fv
			WHERE fv.year = 2016 AND fv.region = 'World';

/* changes in the forest area (in sq km) of the world from 1990 to 2016? */

SELECT MIN ((SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 1990 AND fv.region = 'World') -
			(SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 2016 AND fv.region = 'World')) change 
	FROM forestation fv;
	
/* percent change in forest area of the world between 1990 and 2016 */

SELECT  
		ROUND(MIN ((SELECT MIN ((SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 1990 AND fv.region = 'World') -
			(SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 2016 AND fv.region = 'World')) /
			(SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 1990 AND fv.region = 'World'))) * 100 )
	FROM forestation fv;


/* comparison between forest area loss and area of the countries */
WITH fa_1990 AS (SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 1990 AND fv.region = 'World'),
				fa_change AS (SELECT MIN ((SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 1990 AND fv.region = 'World') -
			                 (SELECT  fv.forest_area FROM forestation fv WHERE fv.year = 2016 AND fv.region = 'World')) 
							  FROM forestation fv)
SELECT *
FROM forestation fv
WHERE fv.year = 2016
ORDER BY ABS(fv.total_land_area_sqkm- (SELECT * FROM fa_change))
		LIMIT 1 ;
		
		
/* percentage of total forest area in 2016 */
SELECT  fv.forest_area_percentage, fv.region
		FROM forestation fv
			WHERE fv.year = 2016 AND fv.region = 'World';
	
	
/* region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places */
SELECT  AVG(fv.forest_area_percentage)forest_prcnt_region, fv.region
		FROM forestation fv
			WHERE fv.year = 2016 
			GROUP BY fv.region
			ORDER BY fv.forest_area_percentage DESC; 


/* percent forest of the entire world in 1990 */
SELECT  fv.forest_area_percentage, fv.region
		FROM forestation fv
			WHERE fv.year = 1990 AND fv.region = 'World';
	
	
/*  Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places */
SELECT  AVG(fv.forest_area_percentage) forest_prcnt_region, fv.region
		FROM forestation fv
			WHERE fv.year = 1990 AND fv.region != 'World'
			GROUP BY fv.region
			ORDER BY forest_prcnt_region DESC;
	
	
/* Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016 */

WITH f_1990 AS (SELECT fv.country,  fv.country_code,fv.region, fv.year year_1990, fv.forest_area forest_area_1990 FROM forestation fv WHERE fv.year = 1990),
	 f_2016 AS (SELECT fv.country, fv.country_code, fv.year year_2016, fv.forest_area forest_area_2016 FROM forestation fv WHERE fv.year = 2016)

SELECT f_2016.country, f_1990.region,
	   f_2016.forest_area_2016 - f_1990.forest_area_1990 forest_area_diff
FROM f_1990
JOIN f_2016
ON  f_1990.country_code = f_2016.country_code AND f_1990.country = f_2016.country
WHERE (f_1990.forest_area_1990 IS NOT NULL) AND (f_2016.forest_area_2016 IS NOT NULL) AND 
		(f_1990.country != 'World')
		ORDER BY forest_area_diff
		LIMIT 5;
		
		
/* Based on the table you created, which regions of the world percent DECREASED in forest area from 1990 to 2016 */

WITH f_1990 AS (SELECT fv.country,  fv.total_land_area_sqkm total_area, fv.country_code,fv.region, fv.year year_1990, fv.forest_area forest_area_1990 FROM forestation fv WHERE fv.year = 1990),
	 f_2016 AS (SELECT fv.country, fv.country_code, fv.year year_2016, fv.forest_area forest_area_2016 FROM forestation fv WHERE fv.year = 2016)

SELECT f_2016.country, f_1990.region,
	   (f_2016.forest_area_2016 - f_1990.forest_area_1990) /(f_1990.forest_area_1990*.01) forest_area_prcnt_diff, f_1990.total_area
FROM f_1990
JOIN f_2016
ON  f_1990.country_code = f_2016.country_code AND f_1990.country = f_2016.country
WHERE (f_1990.forest_area_1990 IS NOT NULL) AND (f_2016.forest_area_2016 IS NOT NULL) AND 
		(f_1990.country != 'World')
		ORDER BY forest_area_prcnt_diff
		LIMIT 5;


/* If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?*/
SELECT DISTINCT (forest_quartiles), COUNT (country) OVER (PARTITION BY forest_quartiles)
FROM (SELECT country , CASE WHEN forest_area_percentage <= 25 THEN 1
					  WHEN forest_area_percentage > 25 AND
							forest_area_percentage <= 50 THEN 2
					  WHEN forest_area_percentage > 50 AND
							forest_area_percentage <= 75 THEN 3
					  ELSE 4 END AS forest_quartiles
	FROM forestation
	WHERE (year = 2016) AND (forest_area_percentage IS NOT NULL) AND (region != 'World') ) q1;



/* List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.*/
SELECT country, region, forest_area_percentage
	FROM forestation
	WHERE (year = 2016) AND (forest_area_percentage > 75) AND (region != 'World')
    ORDER BY forest_area_percentage DESC;


	
/* How many countries had a percent forestation higher than the United States in 2016*/
SELECT COUNT(*) num_countries
FROM(SELECT forest_area_percentage not_USA
	FROM forestation
	WHERE (year = 2016) AND (forest_area_percentage IS NOT NULL) AND 
			(country not LIKE 'United States')) u1
	WHERE (SELECT forest_area_percentage USA
			FROM forestation
			WHERE year = 2016 AND (forest_area_percentage IS NOT NULL) AND 
			 (country LIKE 'United States')) < u1.not_USA