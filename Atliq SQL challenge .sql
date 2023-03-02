
/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. */

SELECT 
      DISTINCT(market) AS markets
FROM  dim_customer
WHERE customer = 'Atliq Exclusive' and region  = 'APAC';



/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020, unique_products_2021, 
    percentage_chg */

SELECT COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN   product.product_code end)) AS product_count_2020,
       COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product.product_code end)) AS product_count_2021,
       (COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN product.product_code end))/COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN product.product_code end)) - 1) *100 AS percentage_cng
FROM dim_product as product
JOIN fact_sales_monthly  as sales
ON  product.product_code = sales.product_code;
	 


/* 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, 
   segment and product_count */

SELECT segment, 
       count(distinct(product_code)) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;



/* 4. Follow-up: 
    Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment, product_count_2020, 
    product_count_2021, difference */

SELECT segment,
	COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN P.product_code END )) AS product_count_2020,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN P.product_code END )) AS product_count_2021,
        COUNT(DISTINCT(CASE WHEN fiscal_year = '2021' THEN P.product_code END )) - 
                                                          COUNT(DISTINCT(CASE WHEN fiscal_year = '2020' THEN P.product_code END )) 
AS difference 
FROM dim_product AS P
JOIN fact_sales_monthly AS S ON P.product_code = S.product_code
GROUP BY segment;
    



/* 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, 
      product, manufacturing_cost */



SELECT dim_product.product_code, 
       product, 
       manufacturing_cost
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
WHERE manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);





/* 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
    The final output contains these fields, customer_code customer average_discount_percentage            */

SELECT dim_customer.customer_code,
       customer,
       avg(pre_invoice_discount_pct) over(partition by dim_customer.customer_code, customer) AS  avg_high_discount_pct
FROM fact_pre_invoice_deductions 
JOIN dim_customer 
ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE fiscal_year = '2021' AND market = 'India'
ORDER BY avg_high_discount_pct DESC LIMIT 5;



/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and 
    high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount.                        */


SELECT MONTHNAME(date) AS month, 
       YEAR(date) AS year, 
       ROUND(SUM(gross_price * sold_quantity ),2)AS gross_sales
FROM dim_customer AS c JOIN  fact_sales_monthly AS s
ON c.customer_code = s.customer_code
JOIN fact_gross_price as p ON p.product_code = s.product_code
WHERE customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(date), YEAR(date);



/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, 
   Quarter, total_sold_quantity                                                                                                          */



SELECT CASE
           WHEN monthname(date) in ('September','October','November') THEN 1
           WHEN monthname(date) in ('December','January','February') THEN 2
           WHEN monthname(date) in ('March','April','May') THEN 3
           WHEN monthname(date) in ('June','July','August') THEN 4
       END AS 'Quarter',
       sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020 
GROUP BY `Quarter`
ORDER BY `total_sold_quantity` DESC;


/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, 
   channel, gross_sales_mln, percentage  */


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
FROM cte2, cte
ORDER BY percentage DESC;



/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, 
   division, product_code, product, total_sold_quantity, rank_order   */


   SELECT * FROM (
         SELECT division, 
                dim_product.product_code,
                CONCAT(product,' ', variant) AS product,
                sum(sold_quantity) AS total_sold_quantity, 
                DENSE_RANK() OVER(PARTITION BY division ORDER BY sum(sold_quantity) DESC ) AS rank_order
	  FROM dim_product
          JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
          WHERE fiscal_year = '2021'
          GROUP BY dim_product.product_code) AS temp
   WHERE rank_order < 4;

    







