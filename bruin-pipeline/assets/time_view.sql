/* @bruin
name: time_view
description: This asset creates a view in BigQuery
             that calculates the total sales by release year.
type: bq.sql

depends: 
   - table_warehouse

@bruin */

CREATE OR REPLACE VIEW `video-490706.game_sales.Sales_by_year` AS
SELECT release_year, ROUND(SUM(total_sales), 2) AS year_sales
FROM `video-490706.game_sales.Videogame_sales`
GROUP BY release_year ORDER BY release_year;