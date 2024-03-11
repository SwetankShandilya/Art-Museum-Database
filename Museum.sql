 use again;
 
 select * from artist;
 select * from canvas_size;
 select * from image_link;
 select * from museum;
 select * from museum_hours;
 select * from product_size;
 select * from work;
 select * from subject;

 							


1) Fetch all the paintings which are not displayed on any museums?
	select * from work where museum_id is null;


2) Are there museuems without any paintings?
	select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id)


3) How many paintings have an asking price of more than their regular price? 
	select * from product_size
	where sale_price > regular_price; 


4) Identify the paintings whose asking price is less than 50% of its regular price 
	select * 
	from product_size
	where sale_price < (regular_price*0.5); 


5) Which canva size costs the most?
	SELECT cs.label AS canva, ps.sale_price
FROM (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk
    FROM product_size
) AS ps
JOIN canvas_size AS cs ON cs.size_id = ps.size_id  -- Proper join condition
WHERE ps.rnk = 1; 
				 


6) Delete duplicate records from work, product_size, subject and image_link tables
	WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY (SELECT 0)) AS rn
    FROM work
)
DELETE FROM CTE WHERE rn > 1;




	WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY work_id, size_id ORDER BY (SELECT 0)) AS rn
    FROM product_size
)
DELETE FROM CTE WHERE rn > 1;


	WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY work_id, subject ORDER BY (SELECT 0)) AS rn
    FROM subject
)
DELETE FROM CTE WHERE rn > 1;

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY (SELECT 0)) AS rn
    FROM image_link
)
DELETE FROM CTE WHERE rn > 1;



7) Identify the museums with invalid city information in the given dataset
	SELECT * FROM museum
    WHERE city LIKE '[0-9]%';



8) Museum_Hours table has 1 invalid entry. Identify it and remove it.
	delete from museum_hours 
	where ctid not in (select min(ctid)
						from museum_hours
						group by museum_id, day );


9) Fetch the top 10 most famous painting subject
	WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY museum_id, day ORDER BY (SELECT 0)) AS rn
    FROM museum_hours
)
DELETE FROM CTE WHERE rn > 1;



10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
	select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');


11) How many museums are open every single day?
	SELECT COUNT(1)
	FROM (
    SELECT museum_id, COUNT(1) AS count_per_museum
    FROM museum_hours
    GROUP BY museum_id
    HAVING COUNT(1) = 7
	) AS x;



12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
	select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;


13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;


14) Display the 3 least popular canva sizes
	SELECT label, ranking, no_of_paintings
	FROM (
    SELECT cs.size_id, cs.label, COUNT(1) AS no_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(1)) AS ranking
    FROM work w
    JOIN product_size ps ON ps.work_id = w.work_id
    JOIN canvas_size cs ON cs.size_id = ps.size_id  -- Removed '::text' conversion
    GROUP BY cs.size_id, cs.label
	) x
	WHERE x.ranking <= 3;



15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
	SELECT museum_name, city, day, [open], [close], duration
	FROM (
    SELECT m.name AS museum_name, m.state AS city, mh.day, mh.[open], mh.[close],
           CONVERT(DATETIME, mh.[open], 108) AS open_time,
           CONVERT(DATETIME, mh.[close], 108) AS close_time,
           CONVERT(DATETIME, mh.[close], 108) - CONVERT(DATETIME, mh.[open], 108) AS duration,
           RANK() OVER (ORDER BY (CONVERT(DATETIME, mh.[close], 108) - CONVERT(DATETIME, mh.[open], 108)) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
	) x
	WHERE x.rnk = 1;




16) Which museum has the most no of most popular painting style?
	with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


17) Identify the artists whose paintings are displayed in multiple countries
	with cte as
		(select distinct a.full_name as artist
		--, w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;


18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
	WITH cte_country AS (
    SELECT country, COUNT(1) AS country_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rnk
    FROM museum
    GROUP BY country
	),
	cte_city AS (
    SELECT city, COUNT(1) AS city_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rnk
    FROM museum
    GROUP BY city
	)
	SELECT STRING_AGG(country, ', ') AS countries, STRING_AGG(city, ', ') AS cities
	FROM cte_country country
	CROSS JOIN cte_city city
	WHERE country.country_rnk = 1
	AND city.city_rnk = 1;



19) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Ensure the previous statement is terminated with a semicolon
WITH cte AS (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk,
           RANK() OVER (ORDER BY sale_price) AS rnk_asc
    FROM product_size
)
SELECT w.name AS painting,
       cte.sale_price,
       a.full_name AS artist,
       m.name AS museum,
       m.city,
       cz.label AS canvas
FROM cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON cz.size_id = cte.size_id -- Removed data type conversion
WHERE rnk = 1 OR rnk_asc = 1;




20) Which country has the 5th highest no of paintings?
	with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;


21) Which are the 3 most popular and 3 least popular painting styles?
	with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;


22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	

	
