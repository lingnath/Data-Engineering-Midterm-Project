-- These are sql files I've created within the Superset UI for further analysis. This one extracts the state code to analyze geographical data

select yr_wk_num, prod_key, store_key, total_sales_amt, no_stock_instances, concat('US-', PROV_STATE_CD) state_code from
awsdatacatalog.{athena db name}.fact left join awsdatacatalog.{athena db name}.store using (store_key)