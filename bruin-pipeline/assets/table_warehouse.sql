/* @bruin
name: table_warehouse
description: This asset creates a table in BigQuery 
             and loads data from Google Cloud Storage.
             Also clusters the table by genre and console 
             for improved query performance.
type: bq.sql
depends: 
   - datalake_ingestion

@bruin */

CREATE OR REPLACE TABLE `video-490706.game_sales.Videogame_sales`
(
  title STRING,
  console STRING,
  genre STRING,
  publisher STRING,
  developer STRING,
  critic_score FLOAT64,
  total_sales FLOAT64,
  release_year INT64
)
CLUSTER BY genre, console;

LOAD DATA INTO `video-490706.game_sales.Videogame_sales`
FROM FILES (
  format = 'CSV',
  uris = ['gs://bruin-test-001/Video_Games_Sales_Cleaned.csv'],
  skip_leading_rows = 1
);