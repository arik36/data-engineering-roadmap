--Cada fila con el promedio de su país al lado, y una columna con la diferencia
WITH promedio_pais AS(
        SELECT country_name, 
        value, 
        AVG(value) OVER (PARTITION BY country_name) AS Average 
        FROM gdp
), promedio_resta AS(
        SELECT country_name,
        (value - Average) AS Diff, 
        Average
	    FROM promedio_pais)

SELECT * FROM promedio_resta;

--Numerar los años de cada país del más alto al más bajo (ROW_NUMBER)

SELECT 
    country_name, 
    country_code, 
    year, 
    value,
    ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY year DESC) AS nume_year
FROM gdp;

--enumerar año y contar total de años
SELECT 
    country_name, 
    year, 
    ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY year DESC) AS numero_de_fila,
    COUNT(year) OVER (PARTITION BY country_name) AS total_years
FROM gdp;

--El año de mayor PIB de cada país — esto necesita una CTE con ROW_NUMBER y luego filtrar por = 1. Es el patrón más útil de todos y se llama "top N por grupo"
WITH añospib_x_pais AS (
    SELECT
        country_name, 
        country_code, 
        year, 
        value,
        ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY value DESC) AS rank_PBI
    FROM gdp
)
SELECT 
    country_name, 
    country_code, 
    year, 
    value, 
    rank_PBI
FROM añospib_x_pais
WHERE rank_PBI = 1;

--Aggregates 15
SELECT COUNT (mem.memid) OVER () AS coun, mem.firstname, mem.surname
FROM cd.members mem
ORDER BY mem.joindate;

 --Produce a monotonically increasing numbered list of members 
 --(including guests), ordered by their date of joining. Remember
 -- that member IDs are not guaranteed to be sequential.
SELECT COUNT (mem.memid) OVER (ORDER BY mem.joindate ) AS coun, mem.firstname, mem.surname
FROM cd.members mem; 


--Output the facility id that has the highest number of slots booked. 
--Ensure that in the event of a tie, all tieing results get output.
WITH todos_registros_con_total AS (SELECT boo.facid, SUM(boo.slots) AS sum,
       RANK() OVER (ORDER BY SUM(boo.slots) DESC) AS posix
	   FROM cd.bookings boo
	   GROUP BY boo.facid
       ORDER BY sum DESC)


SELECT facid, sum AS total
FROM todos_registros_con_total
LIMIT 1;
--Produce a list of members (including guests), along with the number 
--of hours they've booked in facilities, rounded to the nearest ten hours. 
--Rank them by this rounded figure, producing output of first name, surname, 
--rounded hours, rank. Sort by rank, surname, and first name.
select firstname, surname,
	((sum(bks.slots)+10)/20)*10 as hours,
	rank() over (order by ((sum(bks.slots)+10)/20)*10 desc) as rank

	from cd.bookings bks
	inner join cd.members mems
		on bks.memid = mems.memid
	group by mems.memid
order by rank, surname, firstname;    

--Y sobre gdp: el cambio porcentual de un año al siguiente por país.
-- Necesita LAG y una división. Ojo con dividir entre cero y con el
-- primer año, que no tiene anterior y da NULL — es el tema de mañana.
SELECT country_name,
               year,
               value,
               CASE
	          WHEN LAG(year, 1) OVER (PARTITION BY country_name ORDER BY year) IS NULL
	          THEN 0
	          ELSE (value - LAG(value, 1) OVER (PARTITION BY country_name ORDER BY year)) / 
                  NULLIF(LAG(value, 1) OVER (PARTITION BY country_name ORDER BY year), 0)
             END AS CambProc
        FROM gdp;

