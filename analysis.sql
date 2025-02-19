--  Monday coffee -- Data analysis 
SELECT
	*
FROM
	CITY;

SELECT
	*
FROM
	CUSTOMERS;

-- Reports & Data Analysis
-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT
	CITY,
	ROUND((POPULATION * 0.25 / 1000000), 2),
	CITY_RANK
FROM
	CITY
ORDER BY
	CITY_RANK ASC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
	SUM(TOTAL) AS TOTAL_REVENUE
FROM
	SALES
WHERE
	EXTRACT(
		YEAR
		FROM
			SALE_DATE
	) = 2023
	AND EXTRACT(
		QUARTER
		FROM
			SALE_DATE
	) = 4;

-- more refined below 
SELECT
	C.CITY_NAME,
	SUM(S.TOTAL) AS TOTAL_REVENUE
FROM
	SALES S
	JOIN CUSTOMERS CS ON S.CUSTOMER_ID = CS.CUSTOMER_ID
	JOIN CITY C ON C.CITY_ID = CS.CITY_ID
WHERE
	EXTRACT(
		YEAR
		FROM
			S.SALE_DATE
	) = 2023
	AND EXTRACT(
		QUARTER
		FROM
			S.SALE_DATE
	) = 4
GROUP BY
	C.CITY_NAME
ORDER BY
	TOTAL_REVENUE DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT
	P.PRODUCT_NAME,
	COUNT(S.SALE_ID) AS TOTAL_ORDERS
FROM
	PRODUCTS P
	LEFT JOIN SALES S ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
	PRODUCT_NAME
ORDER BY
	TOTAL_ORDERS DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city abd total sale
-- no cx in each these city
SELECT
	C.CITY_NAME,
	SUM(S.TOTAL) AS AMOUNT_PERCITY,
	COUNT(DISTINCT S.CUSTOMER_ID) AS TOTAL_CX,
	ROUND(
		SUM(S.TOTAL)::NUMERIC / COUNT(DISTINCT S.CUSTOMER_ID)::NUMERIC,
		2
	) AS AVG_SALE_PR_CX
FROM
	SALES S
	JOIN CUSTOMERS CU ON S.CUSTOMER_ID = CU.CUSTOMER_ID
	JOIN CITY C ON C.CITY_ID = CU.CITY_ID
GROUP BY
	CITY_NAME
ORDER BY
	AMOUNT_PERCITY DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH
	CITY_TABLE AS (
		SELECT
			C.CITY_NAME,
			ROUND((C.POPULATION * 0.25 / 1000000), 2) AS COFFEE_CONSUMERS_MILLIONS
		FROM
			CITY C
	),
	CUSTOMER_TABLE AS (
		SELECT
			C.CITY_NAME,
			COUNT(DISTINCT CU.CUSTOMER_ID) AS UNIQUE_CUSTOMERS
		FROM
			SALES S
			JOIN CUSTOMERS CU ON S.CUSTOMER_ID = CU.CUSTOMER_ID
			JOIN CITY C ON C.CITY_ID = CU.CITY_ID
		GROUP BY
			CITY_NAME
	)
SELECT
	CT.CITY_NAME,
	CT.COFFEE_CONSUMERS_MILLIONS,
	CUT.UNIQUE_CUSTOMERS
FROM
	CITY_TABLE CT
	JOIN CUSTOMER_TABLE CUT ON CUT.CITY_NAME = CT.CITY_NAME
	-- -- Q6
	-- Top Selling Products by City
	-- What are the top 3 selling products in each city based on sales volume?
SELECT
	*
FROM
	(
		SELECT
			CI.CITY_NAME,
			P.PRODUCT_NAME,
			COUNT(S.SALE_ID) AS TOTAL_ORDERS,
			DENSE_RANK() OVER (
				PARTITION BY
					CI.CITY_NAME
				ORDER BY
					COUNT(S.SALE_ID) DESC
			) AS RANK
		FROM
			SALES AS S
			JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
			JOIN CUSTOMERS AS C ON C.CUSTOMER_ID = S.CUSTOMER_ID
			JOIN CITY AS CI ON CI.CITY_ID = C.CITY_ID
		GROUP BY
			1,
			2
	) AS T1
WHERE
	RANK <= 3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT
	CI.CITY_NAME,
	COUNT(DISTINCT C.CUSTOMER_ID) AS UNIQUE_CX
FROM
	CITY AS CI
	LEFT JOIN CUSTOMERS AS C ON C.CITY_ID = CI.CITY_ID
	JOIN SALES AS S ON S.CUSTOMER_ID = C.CUSTOMER_ID
WHERE
	S.PRODUCT_ID IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY
	CITY_NAME
ORDER BY
	UNIQUE_CX;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
WITH
	AVGSALE AS (
		SELECT
			CI.CITY_NAME,
			COUNT(DISTINCT S.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
			ROUND(
				SUM(S.TOTAL)::NUMERIC / COUNT(DISTINCT S.CUSTOMER_ID)::NUMERIC,
				2
			) AS AVG_SALE_PER_CUSTOMER
		FROM
			SALES S
			JOIN CUSTOMERS CU ON S.CUSTOMER_ID = CU.CUSTOMER_ID
			JOIN CITY CI ON CU.CITY_ID = CI.CITY_ID
		GROUP BY
			CI.CITY_NAME
	),
	CITY_RENT AS (
		SELECT
			CITY_NAME,
			ESTIMATED_RENT
		FROM
			CITY
	)
SELECT
	CT.CITY_NAME,
	AVS.TOTAL_CUSTOMERS,
	AVS.AVG_SALE_PER_CUSTOMER,
	ROUND(
		CT.ESTIMATED_RENT::NUMERIC / AVS.TOTAL_CUSTOMERS::NUMERIC,
		2
	) AS AVG_RENT
FROM
	CITY_RENT CT
	JOIN AVGSALE AVS ON CT.CITY_NAME = AVS.CITY_NAME
ORDER BY
	4 DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


WITH monthly_sales AS (
    SELECT
        city.city_name,
        EXTRACT(MONTH FROM sales.sale_date) AS month,
        EXTRACT(YEAR FROM sales.sale_date) AS year,
        SUM(sales.total) AS total_sales
    FROM
        sales
    JOIN 
        customers ON customers.customer_id = sales.customer_id
    JOIN 
        city ON city.city_id = customers.city_id
    GROUP BY
        city.city_name,
        EXTRACT(MONTH FROM sales.sale_date),
        EXTRACT(YEAR FROM sales.sale_date)
),
growth_ratio 
as
(select
	city_name,
	month,
	year,
	total_sales as cr_month_sales,
	lag(total_sales,1) over(partition by city_name) as last_month_sale
from
	monthly_sales
)


select 
city_name,
month,year,
cr_month_sales,
last_month_sales,
round((cr_month_sales-last_month_sales)::numeric/last_month_sales::numeric*100,2) as growth_rate

from growth_ratio where last_month_sales is not null ;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC





---- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.

