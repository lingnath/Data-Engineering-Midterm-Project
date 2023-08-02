-- These are sql files I've created within the Superset UI for further analysis. This one extracts the month to analyze monthly data
-- Because there are duplicates when joining the fact with the calendar table (7 duplicates due to there being days of the week per yr_wk_num)
-- I had to group by the keys and average the results so that the fact table metrics remain the same as before the join

select yr_wk_num, prod_key, store_key, round(avg(total_sales_amt-total_sales_cost), 5) total_profit, round(avg(total_sales_amt), 5) total_sales_amt, round(avg(no_stock_instances), 5) no_stock_instances, avg(mnth_num) month from
(select * from awsdatacatalog.{athena db name}.fact left join awsdatacatalog.{athena db name}.calendar using (yr_wk_num)) A
group by yr_wk_num, prod_key, store_key
order by yr_wk_num, prod_key, store_key