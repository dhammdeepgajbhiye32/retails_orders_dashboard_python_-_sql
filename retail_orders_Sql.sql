Create database if not exists retail_orders;

use retail_orders;

create table if not exists orders(
order_id int primary Key,
order_date date,
ship_mode varchar(30),
segment varchar(30),
country varchar(30),
city varchar(30),
state varchar(30),
postal_code varchar(20),
region varchar(20),
category varchar(30),
sub_category varchar(30),
product_id varchar(30),
cost_price int,
list_price int,
quantity int,
discount_percent int,
year int,
quarter int,
month_name varchar(20),
month int,
discount_price decimal(10,1),
sales_price decimal(10,1),
profit decimal(10,1)
);

select * from orders;

select distinct region from orders;

# After performing Extract Transform Load mean We Extract the data from Kaggle Server with the help of API and then Transform it into Python with the help of 
# Pandas and we Load the Transformed data into MySQL Database and now we are going to perform Data Analysis into SQL.alter

# So Some Data Analysis Question are:

# 1. Find top 10 highest revnue generating product?

select
	product_id,
    concat(round(sum(sales_price)/1000,2),'K') as total_sales
from orders
group by product_id
order by sum(sales_price) desc
limit 10;

---

# 2. Find top 5 Highest selling products in each Region?

with CTE as
(
	select
		product_id,
        sum(sales_price) as total_sales,
        region,
        dense_rank() 
			over (
				partition by region
                order by sum(sales_price) desc
                ) as D_rank
		from orders
        group by product_id, region
        order by region
)
select * from CTE
where D_rank <= 5;

---

# 3. Find State and City wise count of orders?

select
	state,
    city,
    count(order_id) as total_orders
from orders
group by state, city
order by total_orders desc;

---

# 4. Which category has the highest Sales_price?

select
	category,
    sum(sales_price) as total_sales
from orders
group by category
order by total_sales desc;

---

# 5. Which Sub_Category has the highest Profit?

Select
	category,
    sub_category,
    sum(profit) as total_profit
from orders
group by category, sub_category
order by total_profit desc;

---

# 6. Which Quarter is the best performing at all time?

select
	concat('Q',quarter) as quarter,
    sum(sales_price) as total_sales
from orders
group by quarter
order by total_sales desc;

---

# 7. Find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023?

with CTE as 
(
	select
		year as order_year,
        month as order_month,
        month_name as order_month_name,
        sum(sales_price) as total_sales
	from orders
    group by order_year, order_month, order_month_name
)
select order_month, order_month_name, 
	concat(round(sum(case when order_year = 2022 then total_sales else 0 end)/1000,2),'K') as year_2022,
    concat(round(sum(case when order_year = 2023 then total_sales else 0 end)/1000,2),'K') as year_2023,
    concat(
    round(
		(
			sum(case when order_year = 2023 then total_sales else 0 end) 
			- 
			sum(case when order_year = 2022 then total_sales else 0 end)
		) 
        /
        sum(case when order_year = 2022 then total_sales else 0 end) * 100,2),'%') as '%_Growth_comparision'
from CTE
group by order_month, order_month_name
order by order_month, order_month_name;

---

# 8. For each category which month has the highest sales?

with CTE as
(
	select
		category,
        year,
        month,
        month_name,
        round(sum(sales_price),2) as total_sales
	from orders
    group by category, year, month, month_name
)
select * from
(
select *,
	dense_rank() over (partition by category order by total_sales desc) as D_Rank
from CTE
) as T1
where D_Rank = 1;

---

# 9. Which sub-category had highest growth by profit in 2023 compare to 2022?

with CTE as
(
	select
		sub_category,
        year as order_year,
		sum(profit) as total_profit
	from orders
    group by sub_category, order_year
),
growthCTE as (
select 
	sub_category,
	sum(case when order_year = 2022 then total_profit else 0 end) as year2022,
	sum(case when order_year = 2023 then total_profit else 0 end) as year2023,
    round(
		(
			sum(case when order_year = 2023 then total_profit else 0 end) 
			-
			sum(case when order_year = 2022 then total_profit else 0 end)
		)
		/
		sum(case when order_year = 2022 then total_profit else 0 end)
		* 100,
		2) as Growth_pct
from CTE
group by sub_category
)
select
	sub_category,
    year2022,
    year2023,
    concat(growth_pct,'%') as Growht_comparison
from growthCTE
order by growth_pct desc 
limit 1;