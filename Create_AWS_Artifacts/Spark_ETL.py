import argparse
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from datetime import datetime
import ast

# This ETL file will transform the raw data from the input bucket and then store it in the output
# bucket. The rationale behind the ETL steps are explained in the Spark_EDA.ipynb file.

# Gets all the arguments from the spark steps
parser = argparse.ArgumentParser()
parser.add_argument('--spark_name')
parser.add_argument('--input_path')
parser.add_argument('--data')
parser.add_argument('--output_path')
args = parser.parse_args()
print('Arg parser created')

spark_name = args.spark_name
input_path = args.input_path
print('input_path: ', input_path)
output_path = args.output_path
print('output_path: ', output_path)
data = ast.literal_eval(args.data)

# Creating Spark session
spark = SparkSession.builder.appName(spark_name).getOrCreate()
print('Spark Session Created')

# Creating the Pyspark dataframes for each of the raw tables in the input S3 bucket
for x in data.items():
    exec(f"{x[0]}_df = spark.read.format('csv')\
.option('header', 'true')\
.option('inferSchema', True)\
.load('{x[1]}')")
    exec(f"{x[0]}_df.show(2)")

# Grouping the sales table into daily aggregations (so that we can join with the inventory table)
daily_sales_df = sales_df.groupBy('TRANS_DT', 'PROD_KEY', 'STORE_KEY')\
    .agg(sum('SALES_QTY').alias('SALES_QTY'),\
    sum('SALES_AMT').alias('SALES_AMT'),\
    sum('SALES_COST').alias('SALES_COST')
    )
daily_sales_df.show(2)

# Joining the inventory, sales, and calendar table
sales_inv_calendar_df = inventory_df\
    .join(daily_sales_df, (inventory_df['CAL_DT']==daily_sales_df['TRANS_DT']) & (inventory_df['PROD_KEY']==daily_sales_df['PROD_KEY']) & (inventory_df['STORE_KEY']==daily_sales_df['STORE_KEY']), 'left')\
    .join(calendar_df, inventory_df['CAL_DT']==calendar_df['CAL_DT'], 'left')\
        .select(inventory_df['CAL_DT'], 
                inventory_df['PROD_KEY'],
                inventory_df['STORE_KEY'],
                'SALES_QTY',
                'SALES_AMT',
                'SALES_COST',
                'INVENTORY_ON_HAND_QTY',
                'INVENTORY_ON_ORDER_QTY',
                'OUT_OF_STOCK_FLG',
                'WASTE_QTY',
                'DAY_OF_WK_NUM',
                'YR_WK_NUM'
                )
sales_inv_calendar_df.show(2)

# Filling null values with 0 for the sales columns. The assumption is that the nulls in the sales 
# table means that no sales were made for a product of a particular store on a given day.
sales_inv_calendar_df = sales_inv_calendar_df.na.fill(value=0, subset=['SALES_QTY', 
                                                     'SALES_AMT', 
                                                     'SALES_COST'])

# Creating the EOW Stock Level, EOW Stock on Order, and Low Stock Flg columns 
# For EOW columns, we only populate it if the day of week is Saturday. Otherwise it is null
# The reason for the nulls is so that when we aggregate it, it doesn't affect the EOW values
sales_inv_calendar_df = sales_inv_calendar_df.withColumn('EOW_Stock_Level',
                        when(sales_inv_calendar_df.DAY_OF_WK_NUM==6, sales_inv_calendar_df.INVENTORY_ON_HAND_QTY))\
            .withColumn('EOW_Stock_on_Order',
                        when(sales_inv_calendar_df.DAY_OF_WK_NUM==6, sales_inv_calendar_df.INVENTORY_ON_ORDER_QTY))\
            .withColumn('Low_Stock_Flg', (sales_inv_calendar_df.INVENTORY_ON_HAND_QTY<sales_inv_calendar_df.SALES_QTY).cast('integer'))
sales_inv_calendar_df.show(2)

# Creating the low stock impact, potential low stock impact, and no stock impact columns
# For potential low stock impact and no stock impact, if condition isn't met, we populate with zeros
# The reason is that no impact simply means 0. We would rather have 0 impact than null if there's
# a week where there's no "Low_Stock_Flg" and/or "OUT_OF_STOCK_FLG" instances for a product in a given store
sales_inv_calendar_df = sales_inv_calendar_df.withColumn('low_stock_impact', col('Low_Stock_Flg')+col('OUT_OF_STOCK_FLG'))\
    .withColumn('potential_low_stock_impact', when(col('Low_Stock_Flg')==1, col('SALES_QTY')-col('INVENTORY_ON_HAND_QTY')).otherwise(0))\
    .withColumn('no_stock_impact', when(col('OUT_OF_STOCK_FLG')==1, col('SALES_AMT')).otherwise(0))
sales_inv_calendar_df.show(2)

# Creating the fact table, aggregated by week, product key, and store key
# We average the EOW columns so that it will not affect the EOW values once aggregated
fact_df = sales_inv_calendar_df.groupBy('YR_WK_NUM', 'PROD_KEY', 'STORE_KEY')\
    .agg(
    sum('SALES_QTY').alias('total_sales_qty'),\
    sum('SALES_AMT').alias('total_sales_amt'),\
    (sum('SALES_AMT')/sum('SALES_QTY')).alias('avg_sales_price'),\
    avg('EOW_Stock_Level').alias('EOW_Stock_Level'),\
    avg('EOW_Stock_on_Order').alias('EOW_Stock_on_Order'),\
    sum('SALES_COST').alias('total_sales_cost'),\
    (sum('OUT_OF_STOCK_FLG')/7).alias('percentage_store_out_of_stock'),\
    sum('low_stock_impact').alias('total_low_stock_impact'),\
    sum('potential_low_stock_impact').alias('potential_low_stock_impact'),\
    sum('no_stock_impact').alias('no_stock_impact'),\
    sum('Low_Stock_Flg').alias('low_stock_instances'),\
    sum('OUT_OF_STOCK_FLG').alias('no_stock_instances'),\
    (avg('EOW_Stock_Level')/sum('SALES_QTY')).alias('weeks_on_hand_stock_can_supply')
        )
fact_df.show(2)

# If the sales price is null, this is a divide by 0 error, meaning sales quantity was 0 for those 
# columns. Hence we can assume this means no sales were made which corresponds to a sales price of 0.
fact_df = fact_df.na.fill(value=0, subset='avg_sales_price')
fact_df.show(2)

# Writing the transformed tables to the output bucket in parquet format
store_df.write.option('header', 'true')\
.mode('overwrite')\
.parquet(f"{output_path}store")
print('store table pushed to s3 bucket')

product_df.write.option('header', 'true')\
.mode('overwrite')\
.parquet(f"{output_path}product")
print('product table pushed to s3 bucket')

calendar_df.write.option('header', 'true')\
.mode('overwrite')\
.parquet(f"{output_path}calendar")
print('calendar table pushed to s3 bucket')

fact_df.write.option('header', 'true')\
.mode('overwrite')\
.parquet(f"{output_path}fact")
print('fact table pushed to s3 bucket')