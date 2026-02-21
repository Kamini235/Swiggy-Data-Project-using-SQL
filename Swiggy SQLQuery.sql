--blank or empty string
SELECT *
FROM swiggy_data
WHERE
State =' ' OR City=' ' OR  Restaurant_Name =' ' OR Location=' ' OR Category=' ' OR Dish_Name=' ' 

-- Duplicate detection

SELECT 
State, City, Order_date, Restaurant_Name, Location, Category,Dish_name,
Price_INR,Rating,Rating_count, COUNT(*) AS CNT
from swiggy_data
group by
State, City, Order_date, Restaurant_Name, Location, Category,Dish_name,
Price_INR,Rating,Rating_count
Having COUNT(*)>1

-- Delete dulicates

WITH CTE AS (
SELECT *, ROW_NUMBER() OVER (
PARTITION BY State, City, Order_date, Restaurant_Name, Location, Category,Dish_name,
Price_INR,Rating,Rating_count
ORDER BY (SELECT NULL)
) AS RN
FROM swiggy_data
)
DELETE FROM CTE  WHERE RN>1

--DATA MODEL--- CREATING SCHEMA
-- DIMENTION DATE TABLE

CREATE TABLE dim_date(
date_id INT IDENTITY (1 ,1) PRIMARY KEY,
Full_date  DATE,
Year INT,
Month INT,
Month_name varchar(20),
Quarter INT,
Day INT,
Week INT
)

SELECT *
FROM swiggy_data

-- CREATE DIM  LOCATION

CREATE TABLE dim_location (
location_id INT IDENTITY(1,1) PRIMARY KEY,
State VARCHAR(100),
City VARCHAR(100),
Location VARCHAR(200)
);

---- CREATE DIM RESTAURANT

CREATE TABLE dim_restaurant (
restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
Restaurant_name VARCHAR(200)
);

-- CREATE DIM  CATEGORY

CREATE TABLE dim_category (
category_id INT IDENTITY(1,1) PRIMARY KEY,
category VARCHAR(200)
);

-- CREATE DIM  DISH

CREATE TABLE dim_dish (
dish_id INT IDENTITY(1,1) PRIMARY KEY,
Dish_name VARCHAR(200)
)

--FACT TABLE
CREATE TABLE Fact_swiggy_orders (
 order_id INT IDENTITY(1,1) PRIMARY KEY,
 date_id INT,
 Price_INR DECIMAL(10,2),
 Rating DECIMAL(4,2),
 Rating_count INT,

 location_id INT,
 restaurant_id INT,
 category_id INT,
 dish_id INT,

 FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
 FOREIGN KEY (location_id) REFERENCES dim_location(location_id), 
 FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
 FOREIGN KEY (category_id) REFERENCES dim_category(category_id), 
 FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
 );

 SELECT *
FROM Fact_swiggy_orders

--INSERT DATA IN TABLE
--DIM DATE
INSERT INTO dim_date(Full_date,Year,Month,Month_name,Quarter,Day,Week)
SELECT DISTINCT
  Order_Date,
  Year(Order_Date),
  MONTH(Order_Date),
  DATENAME(MONTH,Order_Date),
  DATEPART(Quarter,Order_Date),
  DAY(Order_Date),
  DATEPART(WEEK,Order_Date)
FROM swiggy_data
where Order_Date is not null;

SELECT * FROM swiggy_data
SELECT * FROM dim_date

--DIM LOCATION
INSERT INTO dim_location( State,City,Location)
SELECT DISTINCT
    State,
    City,
    Location
FROM swiggy_data;

SELECT * FROM dim_location

--dim restaurant
INSERT INTO dim_restaurant(Restaurant_name)
SELECT DISTINCT
    Restaurant_Name
FROM swiggy_data;

SELECT * FROM dim_restaurant

--dim category

INSERT INTO dim_category( category)
SELECT DISTINCT
   Category
FROM swiggy_data;

SELECT * FROM dim_category

-- dim dish
INSERT INTO dim_dish( Dish_name)
SELECT DISTINCT
   Dish_Name
FROM swiggy_data;

SELECT * FROM dim_dish

--fact table
INSERT INTO Fact_swiggy_orders
( 
date_id,
Price_INR,
Rating,
Rating_count,
location_id,
restaurant_id,
category_id,
dish_id
)
SELECT 
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_count,

    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id

FROM swiggy_data s

join dim_date dd
   ON dd.Full_date = s.Order_Date

join dim_location dl
   ON dl.State = s.State
   AND dl.City = s.City
   AND dl.location = s.Location

join dim_restaurant dr
   ON dr.Restaurant_name = s.Restaurant_Name

join dim_category dc
   ON dc.category = s.Category
   
join dim_dish dsh
   ON dsh.Dish_name = s.Dish_Name
;

SELECT * FROM Fact_swiggy_orders

-- to see all at time

SELECT * FROM Fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish dsh ON f.dish_id = dsh.dish_id

-- KPIs

SELECT * 
FROM swiggy_data

--TOTAL ORDER
SELECT COUNT (*) AS total_order
FROM Fact_swiggy_orders

-- to find data type of colomn
SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'swiggy_data';


-- total revenue INR million
SELECT
FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000,'N2') + ' INR Million'
AS Total_revenue
from Fact_swiggy_orders


--avrage rating
SELECT
AVG(Rating)
from dbo.Fact_swiggy_orders


--avrage dish price
SELECT
FORMAT(AVG(CONVERT(FLOAT,Price_INR)), 'N2')+ ' INR'
from dbo.Fact_swiggy_orders

-- Deep dive bussiness analysis
--monthly order treds

SELECT
d.year,
d.month,
d.month_name,
count(*) as total_orders
from Fact_swiggy_orders f
join dim_date d ON f.date_id = d.date_id
group by d.year,
d.month,
d.month_name


-- if YOU want  -- ORDER BYCOUNT(*) DESC
               -- SUM( Price_INR) as Total revenue

-- Quarterly trend
SELECT
d.year,
d.Quarter,
count(*) as total_orders
from Fact_swiggy_orders f
join dim_date d ON f.date_id = d.date_id
group by d.year,
d.Quarter

-- yearly trend
SELECT
d.year,
count(*) as total_orders
from Fact_swiggy_orders f
join dim_date d ON f.date_id = d.date_id
group by d.year

-- order by day of week
SELECT
    DATENAME (WEEKDAY,d.full_date) As day_name,
    count(*)As total_orders
from Fact_swiggy_orders f
join dim_date d ON f.date_id = d.date_id
group by DATENAME (WEEKDAY,d.full_date), DATEPART(WEEKDAY,d.full_date)
ORDER BY DATEPART(WEEKDAY,d.full_date);

-- TOP 10 CITY BY ORDER VALUE
SELECT
TOP 10
l.city,
count(*) As total_order
from Fact_swiggy_orders f
join dim_location l
ON l.location_id = f.location_id
group by l.city
order by count(*) DESC

-- IF YOU WANT total revenue .. replace count
-- sum  (f.price_INR) As total _ revenue ... also change order by

-- revenue contribution by state
SELECT
l.State,
SUM( f.Price_INR) As total_Revenue
from Fact_swiggy_orders f
join dim_location l
ON l.location_id = f.location_id
group by l.State
order by sum(price_INR) DESC


-- top 10 CATEGORY by order VALUE
SELECT
TOP 10
    c.category,
    COUNT(*)As total_orders
from Fact_swiggy_orders f
join dim_category c
ON c.category_id = f.category_id
group by c.category
order by total_orders DESC

--most order dish
SELECT
   d.dish_name,
    COUNT(*)As order_count
from Fact_swiggy_orders f
join dim_dish d
ON d.dish_id = f.dish_id
group by Dish_name
order by order_count DESC

--cuisine performance(order+avg rating)
SELECT
    c.category,
    COUNT(*)As total_orders,
    AVG(convert(float,f.rating)) as avg_rating
from Fact_swiggy_orders f
join dim_category c
ON c.category_id = f.category_id
group by c.category
order by total_orders DESC

-- total order by price range
SELECT
    CASE
        WHEN CONVERT(FLOAT, Price_INR)<100 THEN 'UNDER 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END AS Price_range,
    COUNT(*) AS total_orders
from Fact_swiggy_orders
GROUP BY
    CASE
         WHEN CONVERT(FLOAT, Price_INR)<100 THEN 'UNDER 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END
ORDER BY TOTAL_ORDERS DESC;

-- RATING COUNT DISTRIBUTION
SELECT
    rating,
    COUNT(*) AS rating_count
    from Fact_swiggy_orders
    group by rating
    order by rating

    SELECT
    rating,
    COUNT(*) AS rating_count
    from Fact_swiggy_orders
    group by rating
    order by COUNT(*) desc