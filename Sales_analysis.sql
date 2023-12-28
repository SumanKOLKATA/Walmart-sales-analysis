create database year_sales;
use year_sales;

CREATE TEMPORARY TABLE jan_data (

SELECT Order_ID, Product, Price_Each,Quantity_Ordered, 
SUBSTRING_INDEX(SUBSTRING_INDEX(Purchase_Address,',', -2), ',', 1)  AS city_location,
SUBSTRING_INDEX(order_date,' ', 1)  AS date_of_order,
SUBSTRING_INDEX(order_date,' ', -1)  AS order_time,
SUBSTRING_INDEX(Purchase_Address, ',', -1)  AS pin_state

from sales_january_2019)

select * from jan_data


CREATE TEMPORARY TABLE feb_data (

SELECT Order_ID, Product, Price_Each,Quantity_Ordered, 
SUBSTRING_INDEX(SUBSTRING_INDEX(Purchase_Address,',', -2), ',', 1)  AS city_location,
SUBSTRING_INDEX(order_date,' ', 1)  AS date_of_order,
SUBSTRING_INDEX(order_date,' ', -1)  AS order_time,
SUBSTRING_INDEX(Purchase_Address, ',', -1)  AS pin_state

from sales_february_2019)

select * from feb_data

CREATE TEMPORARY TABLE march_data (

SELECT Order_ID, Product, Price_Each,Quantity_Ordered, 
SUBSTRING_INDEX(SUBSTRING_INDEX(Purchase_Address,',', -2), ',', 1)  AS city_location,
SUBSTRING_INDEX(order_date,' ', 1)  AS date_of_order,
SUBSTRING_INDEX(order_date,' ', -1)  AS order_time,
SUBSTRING_INDEX(Purchase_Address, ',', -1)  AS pin_state

from sales_march_2019)

CREATE TEMPORARY TABLE april_data (

SELECT Order_ID, Product, Price_Each,Quantity_Ordered, 
SUBSTRING_INDEX(SUBSTRING_INDEX(Purchase_Address,',', -2), ',', 1)  AS city_location,
SUBSTRING_INDEX(order_date,' ', 1)  AS date_of_order,
SUBSTRING_INDEX(order_date,' ', -1)  AS order_time,
SUBSTRING_INDEX(Purchase_Address, ',', -1)  AS pin_state

from sales_april_2019)
select * from april_data

create temporary table 1st_qrt (

(select Order_ID, Product, Price_Each,Quantity_Ordered,city_location,date_of_order,order_time,pin_state from jan_data)
union 
(select Order_ID, Product, Price_Each,Quantity_Ordered,city_location,date_of_order,order_time,pin_state from feb_data)
union all
(select Order_ID, Product, Price_Each,Quantity_Ordered,city_location,date_of_order,order_time,pin_state from march_data)
)

select * from 1st_qrt


create temporary table 1st_qrt_extarct (
SELECT Order_ID, Product, Price_Each,Quantity_Ordered, city_location,order_time,pin_state,
SUBSTRING_INDEX(date_of_order,'/', -1)  as year, 
SUBSTRING_INDEX(date_of_order,'/', 1)  as month ,
SUBSTRING_INDEX(SUBSTRING_INDEX(date_of_order, '/', 2), '/', -1) as date
from 1st_qrt
)
 select *from 1st_qrt_extarct

create temporary table j_m_month (
select *, case when year = "19" then "2019" else "19" end as year_2
from 1st_qrt_extarct)

select *from j_m_month

create temporary table j_m_month_ord(
SELECT *,
CONCAT(year_2, '-', LPAD(month, 2, '0'), '-', LPAD(date, 2, '0')) AS ord_date
FROM j_m_month);

create temporary table clean_info(
select Order_ID,ord_date,order_time,Product,Price_Each,Quantity_Ordered,city_location,pin_state
from j_m_month_ord)


update clean_info 
set ord_date = date_format(ord_date,'%y/%m/%d')
    
select* from clean_info

create temporary table clean_info_2(
SELECT *, 
DAYNAME(ord_date) as day_name,
monthname(ord_date) as month_name,
SUBSTRING_INDEX(trim(pin_state), ' ', 1)  as state
FROM clean_info)

create temporary table dim_sale_qrt_1(
select Order_ID,ord_date,order_time,Product,Price_Each,Quantity_Ordered,city_location,day_name,month_name,state
from clean_info_2)
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
select *from dim_sale_qrt_1

## Q1. Number of unique cities 
select distinct (city_location) from dim_sale_qrt_1

## Q2. Number of unique Product 
select distinct (Product) from  dim_sale_qrt_1

## Q3. Number of unique state 
select distinct (state) from dim_sale_qrt_1

## Add column time_category based on order_time

ALTER TABLE dim_sale_qrt_1 ADD COLUMN time_category text(20)

UPDATE dim_sale_qrt_1
SET time_category = (
CASE

WHEN TIME(order_time) BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
WHEN TIME(order_time) BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
WHEN TIME(order_time) BETWEEN '18:00:00' AND '20:59:59' THEN 'Evening'
ELSE 'Night'
END)

select * from dim_sale_qrt_1

## Q4. month wise sales 
 # Add sales column 
 
ALTER TABLE dim_sale_qrt_1 ADD COLUMN sales int

UPDATE dim_sale_qrt_1
SET  sales= (
price_each * Quantity_Ordered )

create table sales_details(
select * from dim_sale_qrt_1)

# monthly sales 

select month_name, sum(sales) as total_sales from dim_sale_qrt_1
group by month_name
order by total_sales desc

## Q5.highest effective time_preiod of sales 

create table time_preiod_sales(
select time_category, sum(sales) as effective_time from dim_sale_qrt_1
group by time_category
order by effective_time desc)

## Q6. sales of products based on sales volume
select Product, sum(sales) as product_performance from dim_sale_qrt_1
group by Product
order by product_performance desc

## Q7. sales on days  based on sales volume
select day_name, sum(sales) as day_wise_performance from dim_sale_qrt_1
group by day_name
order by day_wise_performance desc

## Q8. numbr of products sold in months 
select month_name, sum(Quantity_Ordered) quantity_sold from dim_sale_qrt_1
group by month_name
order by quantity_sold desc

## Q8. numbr of products sold in month of January
create table product_sales_jan(
select Product, sum(Quantity_Ordered) number_of_qnty_jan from dim_sale_qrt_1
where month_name ="january"
group by Product 
order by number_of_qnty_jan desc ) 

## Q9. numbr of products sold in month of Februay
create table product_sales_feb(
select Product, sum(Quantity_Ordered) number_of_qnty_feb from dim_sale_qrt_1
where month_name ="february"
group by Product 
order by number_of_qnty_feb desc  )

## Q9. numbr of products sold in month of Februay
create table product_sales(
select Product, sum(Quantity_Ordered) number_of_qnty_mar from dim_sale_qrt_1
where month_name ="march"
group by Product 
order by number_of_qnty_mar desc)


## Top performer of january for sales among city_location 

create table city_sales(
select city_location, sum(sales) sales_of_citie from dim_sale_qrt_1
group by city_location
)



