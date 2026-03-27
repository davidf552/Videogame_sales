/* @bruin
name: distribution_view
description: This asset creates a view in BigQuery 
             that calculates the total sales by release year and console.
type: bq.sql

depends: 
   - table_warehouse
@bruin */


CREATE OR REPLACE VIEW `video-490706.game_sales.Sales_by_console` AS
SELECT console, ROUND(SUM(total_sales), 2) AS year_sales, 
    ROUND(SUM(total_sales) * 100.0 / SUM(SUM(total_sales)) OVER (), 2) AS pct_sales
FROM `video-490706.game_sales.Videogame_sales`
GROUP BY console
ORDER BY year_sales DESC;
