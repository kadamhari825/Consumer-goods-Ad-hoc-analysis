-- 1
SELECT 
      DISTINCT(market) AS markets
FROM  dim_customer
WHERE customer = 'Atliq Exclusive' and region  = 'APAC';


-- 2
SELECT COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product end)) AS product_count_2020,
       COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product end)) AS product_count_2021,
       (COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product end))/COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product end)) - 1) *100 AS percentage_cng
FROM dim_product
JOIN fact_sales_monthly 
ON  dim_product.product_code = fact_sales_monthly.product_code;
	 

-- 3
SELECT segment, 
       count(distinct(product)) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


-- 4
SELECT segment,
		COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product END )) AS product_count_2020,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product END )) AS product_count_2021,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product END )) - 
                                                   COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product END )) 
AS difference 
FROM dim_product
JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
GROUP BY segment;
    


-- 5
SELECT dim_product.product_code, 
       product, 
       MAX(manufacturing_cost) as manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
ON dim_product.product_code  = fact_manufacturing_cost.product_code

            UNION
            
SELECT dim_product.product_code, product, 
       MIN(manufacturing_cost) as manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
ON dim_product.product_code  = fact_manufacturing_cost.product_code;



-- 6
SELECT dim_customer.customer_code,
       customer,
       avg(pre_invoice_discount_pct) over(partition by dim_customer.customer_code, customer) as high
FROM fact_pre_invoice_deductions 
JOIN dim_customer 
ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE fiscal_year = '2021' AND market = 'India'
ORDER BY high DESC LIMIT 5;


-- 7
SELECT MONTHNAME(date) AS month, 
       YEAR(date) AS year, 
       ROUND(SUM(gross_price),2) AS gross_price
FROM dim_customer AS c JOIN  fact_sales_monthly AS s
ON c.customer_code = s.customer_code
JOIN fact_gross_price as p ON p.product_code = s.product_code
WHERE customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(date), YEAR(date);


-- 8
SELECT  QUARTER(date) ,
        MAX(sold_quantity) total_sold_quantity
FROM fact_sales_monthly
WHERE year(date)  = '2020'
GROUP BY quarter(date)
ORDER BY best_sales DESC ;

-- 9
WITH cte AS (
           SELECT dim_customer.channel, 
                  sum( sold_quantity) as gross_sales  
		   FROM dim_customer 
           JOIN fact_sales_monthly 
           ON dim_customer.customer_code = fact_sales_monthly.customer_code
           WHERE fiscal_year = '2021'
		   GROUP BY channel),
            
    cte2 AS (SELECT SUM(gross_sales)  as total
          FROM cte)

SELECT channel,
       gross_sales / 1000000 AS gross_sales_mln ,
       ROUND((gross_sales /total)* 100,2) AS percentage 
from cte2, cte
ORDER BY percentage DESC;


-- 10
SELECT * 
FROM (
      SELECT division, 
             dim_product.product_code,
             product,
             sold_quantity, 
             DENSE_RANK() OVER(PARTITION BY division ORDER BY sold_quantity DESC ) AS rnk 
	 FROM dim_product
     JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
     WHERE fiscal_year = '2021') AS temp
WHERE rnk < 4



















