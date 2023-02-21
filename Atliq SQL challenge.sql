-- 1
SELECT 
      DISTINCT(market) AS markets
FROM  dim_customer
WHERE customer = 'Atliq Exclusive' and region  = 'APAC';


-- 2
SELECT COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product.product_code end)) AS product_count_2020,
       COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product.product_code end)) AS product_count_2021,
       (COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product.product_code end))/COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product.product_code end)) - 1) *100 AS percentage_cng
FROM dim_product as product
JOIN fact_sales_monthly  as sales
ON  product.product_code = sales.product_code;
	 

-- 3
SELECT segment, 
       count(distinct(product_code)) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


-- 4
SELECT segment,
		COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN P.product_code END )) AS product_count_2020,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN P.product_code END )) AS product_count_2021,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN P.product_code END )) - 
                                                   COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN P.product_code END )) 
AS difference 
FROM dim_product AS P
JOIN fact_sales_monthly AS S ON P.product_code = S.product_code
GROUP BY segment;
    


-- 5
SELECT dim_product.product_code, 
       product, manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
ON dim_product.product_code  = fact_manufacturing_cost.product_code
WHERE manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)

            UNION
            
SELECT dim_product.product_code, product, 
       manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
ON dim_product.product_code  = fact_manufacturing_cost.product_code
where manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);



-- 6
SELECT dim_customer.customer_code,
       customer,
       avg(pre_invoice_discount_pct) over(partition by dim_customer.customer_code, customer) as avg_high_discount_pct
FROM fact_pre_invoice_deductions 
JOIN dim_customer 
ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE fiscal_year = '2021' AND market = 'India'
ORDER BY avg_high_discount_pct DESC LIMIT 5;


-- 7
SELECT MONTHNAME(date) AS month, 
       YEAR(date) AS year, 
       ROUND(SUM(gross_price * sold_quantity ),2)AS gross_sales
FROM dim_customer AS c JOIN  fact_sales_monthly AS s
ON c.customer_code = s.customer_code
JOIN fact_gross_price as p ON p.product_code = s.product_code
WHERE customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(date), YEAR(date);


-- 8
SELECT  QUARTER(date) AS quarter ,
        sum(sold_quantity) total_sold_quantity
FROM fact_sales_monthly
WHERE year(date)  = '2020'
GROUP BY quarter(date)
ORDER BY total_sold_quantity DESC ;

-- 9
WITH cte AS (
           SELECT dim_customer.channel, 
               sum( sold_quantity * gross_price ) as gross_sales  
		   FROM dim_customer 
           JOIN fact_sales_monthly 
           ON dim_customer.customer_code = fact_sales_monthly.customer_code
           join fact_gross_price on  fact_gross_price.product_code = fact_sales_monthly.product_code
           WHERE fact_sales_monthly.fiscal_year = '2021'
		   GROUP BY channel),
            
    cte2 AS (SELECT SUM(gross_sales)  as total
          FROM cte)

SELECT channel,
       ROUND(gross_sales / 1000000,2) AS Gross_sales_mln ,
       ROUND((gross_sales /total)* 100,2) AS Percentage 
from cte2, cte
ORDER BY percentage DESC;


-- 10

   SELECT * FROM (
      SELECT division, 
             dim_product.product_code,
             product,
             sum(sold_quantity) AS total_sold_quantity, 
             DENSE_RANK() OVER(PARTITION BY division ORDER BY sum(sold_quantity) DESC ) AS rnk 
	 FROM dim_product
     JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
     WHERE fiscal_year = '2021'
     GROUP BY dim_product.product_code) AS temp
WHERE rnk < 4

    







