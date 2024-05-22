-- To see the tables in database
SELECT * FROM information_schema.tables
WHERE table_schema = 'public'

-- To see columns of all tables

SELECT * FROM information_schema.columns
WHERE table_schema = 'public' and column_name = 'artist_id'

-- Fetch all the paintings which are not displayed on any museums
SELECT * FROM work
WHERE museum_id is null

-- Are there museums without paitings
SELECT * FROM work
WHERE work_id is null

-- How many paintings have asking price more than regular price
SELECT * FROM product_size
WHERE sale_price > regular_price

-- Pinting whose sale price less than 50%  regular price
SELECT * FROM product_size
WHERE sale_price < (regular_price*50/100)

-- Which canvas size cost the most
SELECT work_id, size_id, sale_price FROM product_size
WHERE sale_price = (SELECT max(sale_price) FROM product_size)


--  Deleting the duplicate records

SELECT work_id, name, artist_id, style,museum_id, COUNT(*) 
FROM work
GROUP BY work_id, name, artist_id, style,museum_id  
HAVING count(*)>1
DELETE FROM work
WHERE work_id NOT IN (
SELECT (MIN(work_id))FROM work
GROUP BY work_id, name, artist_id, style,museum_id )


-- Museum with invalid city information
SELECT * FROM museum 
WHERE city ~ '^[0-9]'	

-- Museum_Hours table has 1 invalid entry. Identify it and remove it
DELETE FROM museum_hours
WHERE ctid NOT IN (SELECT MIN(ctid)
					   FROM museum_hours
					   GROUP BY museum_id,day)
				
-- Fetch the top 10 most famous painting subject
SELECT s.subject, COUNT(*) as no_of_painting FROM work w
JOIN subject s ON s.work_id = w.work_id
GROUP BY subject
ORDER BY no_of_painting DESC
LIMIT 10


-- Identify the museums which are open on both Sunday and Monday. Display museum name, city
SELECT museum.name,museum.city FROM museum_hours mh
JOIN museum ON museum.museum_id = mh.museum_id
WHERE mh.day = 'Sunday' and exists(select 1 from museum_hours mh2
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday')

-- How many museums are open every single day
SELECT COUNT(*) FROM (SELECT museum_id, count(*) FROM museum_hours
GROUP BY museum_id
HAVING count(*) = 7)

-- Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum

SELECT work.museum_id,museum.name,museum.city,museum.country,
Count(work_id) FROM work
join museum on museum.museum_id = work.museum_id
GROUP BY work.museum_id, museum.name, museum.city,museum.country
ORDER BY COUNT(work_id) DESC
LIMIT 5

--  Who are the top 5 most popular artist?
SELECT a.full_name, COUNT(*) FROM artist a
JOIN WORK w ON a.artist_id = w.artist_id
GROUP BY a.full_name
ORDER BY COUNT(*) DESC
LIMIT 5

-- Display the 3 least popular canvas sizes
SELECT * FROM (SELECT label, COUNT(*) AS no_of_painting, DENSE_RANK()
OVER(ORDER BY COUNT(*)) AS Ranking
FROM canvas_size cs
JOIN product_size ps ON cs.size_id::text = ps.size_id
GROUP BY label
ORDER BY COUNT(*) ASC)
WHERE ranking <=3

--Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
SELECT name, state,open,close,day, duration FROM (
SELECT museum.name as name,museum.state as state,open,close,day,to_timestamp(close,'HH:MI AM')-
to_timestamp(open,'HH:MI:AM') AS duration FROM museum_hours
JOIN museum ON museum.museum_id = museum_hours.museum_id)
ORDER BY duration DESC
LIMIT 1

--Which museum has the most no of most popular painting style
SELECT museum.name, style, COUNT(*) FROM work
JOIN museum ON museum.museum_id = work.museum_id
GROUP BY museum.name,style
ORDER BY COUNT(*) DESC
LIMIT 1

--Identify the artists whose paintings are displayed in multiple countries
SELECT full_name,
COUNT(DISTINCT(museum.country)) FROM artist
JOIN work ON work.artist_id = artist.artist_id
JOIN museum ON museum.museum_id = work.museum_id
GROUP BY full_name
HAVING COUNT(DISTINCT(museum.country))>1
ORDER BY COUNT(DISTINCT(museum.country))DESC

-- Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma
WITH country as 
        (SELECT country, COUNT(*), RANK() OVER(ORDER BY COUNT(*)DESC) AS rnk
		 FROM museum
		GROUP BY country),
	city as(
	        SELECT city, COUNT(*), RANK() OVER(ORDER BY COUNT(*)DESC) AS rnk
		 FROM museum
		GROUP BY city)
		
	SELECT string_agg(DISTINCT country.country,' , '), string_agg(city.city, ' ,')
	FROM country
	cross join city
	where country.rnk = 1 and city.rnk = 1
		
--Identify the artist and the museum where the most expensive and least expensive painting is placed
--Display the artist name, sale_price, painting name, museum name, museum city and canvas label

With sizes as(
              Select *, RANK() OVER(ORDER BY
product_size.sale_price DESC) AS rnk_dsc, RANK() OVER(ORDER BY
product_size.sale_price ASC) AS rnk_asc FROM product_size)
select artist.full_name, sizes.sale_price, work.name,
museum.name,museum.city,canvas_size.label, rnk_dsc, rnk_asc FROM artist
JOIN work ON artist.artist_id = work.artist_id
JOIN museum ON museum.museum_id = work.museum_id
JOIN sizes ON sizes.work_id = work.work_id
JOIN canvas_size ON canvas_size.size_id = sizes.size_id::NUMERIC
WHERE rnk_dsc = 1 or rnk_asc = 1

--Which country has the 5th highest no of paintings
WITH cte as (SELECT museum.country as country, COUNT(*) AS no_of_paintings, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS Ranks
FROM museum
JOIN work on work.museum_id = museum.museum_id
GROUP BY museum.country)
SELECT country, no_of_paintings FROM cte
where Ranks = 5

--Which are the 3 most popular and 3 least popular painting styles?

with ct1 as (
           SELECT work.style AS styles,COUNT(*) AS no_of_style,
	       DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rk_dsc,
           DENSE_RANK() OVER(ORDER BY COUNT(*) ASC) AS rk_asc FROM work
           where work.style is not null
	       GROUP BY work.style)
		   
SELECT styles, no_of_style, CASE WHEN rk_dsc<=3 THEN 'Most Popular'
ELSE 'Least Popular' END AS Remarks FROM ct1
WHERE rk_dsc<=3 OR rk_asc<=3
ORDER BY no_of_Style DESC

--  Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality
SELECT name, nationality, no_of_painting, Rnk FROM(
SELECT artist.full_name as name, subject.subject as subject,artist.nationality as nationality,
COUNT(*) as no_of_painting,DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS Rnk FROM artist
JOIN work on work.artist_id = artist.artist_id
JOIN subject on subject.work_id = work.work_id
JOIN museum on museum.museum_id = work.museum_id 
where museum.country!='USA' AND Subject = 'Portraits'
GROUP BY artist.full_name, subject.subject,artist.nationality)
WHERE Rnk = 1

