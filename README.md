#  Data Engineering Zoomcamp 2026 Capstone Project Videogame_sales

## Introduction
Which gaming consoles are popular? What about the revenue they attract?
These questions and more can be resolved with: DATA.
It is important to get up-to-date information regarding sales and the public's perception about which console is the best.

In this project: 
* A yearly report about videogame sales will be transported from its source to Google Cloud Storage GCS (data lake). [Dataset location](https://www.kaggle.com/datasets/bhushandivekar/video-game-sales-and-industry-data-1980-2024/data)
* From GCS, it will go into Google BigQuery (data warehouse).
* Inside BigQuery, two transformations will take place and create two different Views, where Looker Studio (dashboard) will present them in a graphical manner.


How will these 3 steps be executed? It can be done manually one at a time, but there is a better way: a data pipeline.
Bruin will be the data platform employed to build all the above and in simple steps.

[Online dashboard](https://lookerstudio.google.com/s/gzHHnAxkZss)


![Project Dahboard](https://github.com/davidf552/Videogame_sales/blob/main/images/dashboard1.png)


## Table of Contents
- [Setup](#setup)
- [Batch Setup](#batch)
- [Bruin Assets](#bruin-assets)
- [Step 1: Data Lake](#step-1-data-lake)
- [Step 2: Data Warehouse](#step-2-data-warehouse)
- [Step 3: View Creation](#step-3-view-creation)
- [Pipeline](#pipeline)
<br><br>
![Project_schematics](https://github.com/davidf552/Videogame_sales/blob/main/images/Zoomcamp_project2026.png)

## Setup
### Google Cloud Services
* You will need a GC account for this project: https://cloud.google.com/
* After you get one, create a new project and a service account with the following permissions: BigQuery Admin and Storage Admin.
* Generate the service keys and download the json file. Keep it in a safe place.
* Take note of the project ID

<br>

### Terraform
You will need to download and install Terraform in order to prepare the data lake and data warehouse for the pipeline. https://developer.hashicorp.com/terraform

Also, be sure it is on the system's PATH.

<br>


### VSCode
This project was made using VSCode with Bruin. Create a new project in the directory of your choice.

<br>

### Bruin
Install Bruin: One way is using the Git Bash terminal inside VSCode
```bash
curl -LsSf https://getbruin.com/install/cli | sh

```
If it doesn't work, check the following link for more detailed instructions: https://getbruin.com/docs/bruin/getting-started/introduction/installation.html

Once installed, it is recommended to get the Bruin VSCode extension. You can find it on the extensions tab inside VSCode.


<br>

### VSCode (continued)
It is time to use Terraform. First, you need to tell Terraform what provider you will use. Create a file called main.tf and write the following:
```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.24.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-east4"
}
```
Note that you will need to specify the variable var.project_id. It will be done on a separate .tf file.
Then you will need to create a Google Cloud Storage bucket.
```hcl
resource "google_storage_bucket" "bruin_bucket" {
  name          = "bucket_name"
  location      = "us-east4"

}

```
After that, you will need a BigQuery dataset.
```hcl
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "game_sales"
  location   = "us-east4"
}

```
Create a new file called variables.tf and write the following:
```hcl

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "video-490706"
}

```
Replace the default field with the project ID you noted earlier.
<br>

Now is a good time to authenticate to Google Cloud using the json file you downloaded before. 
Set the GOOGLE_APPLICATION_CREDENTIALS environment variable to the path of the JSON file.

After authentication, Terraform has to create the 3 objects:

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply
```
Finally, it is Bruin's turn. 

```bash
bruin init
```

In the .bruin.yml file just created, you will need to set up the connection to both the data lake and the warehouse:
```yml
default_environment: default
environments:
  default:
    connections:
      # Cloud storage connection
      gcs:
        - name: "gcs-prod"
          project_id: "video-490706"
          bucket_name: "bucket_name"
          path_to_file: "project"
          service_account_file: "credentials.json"

      # Data warehouse connection
      google_cloud_platform:
        - name: "gcp-prod"
          project_id: "video-490706"
          service_account_file: "credentials.json"


```
Replace "credentials.json" with the path to where you stored your service account credentials.
## Batch
Also, you need to put those connections inside the pipeline.yml file:
```yml
name: bruin-init
schedule: "0 0 1 1 *"
start_date: "2026-03-27"
catchup: false

default_connections:
    google_cloud_platform: "gcp-prod"
    gcs: "gcs-prod"
    

```
This tells Bruin to run the pipeline once a year, since the dataset is updated annually.
### Note
If there are any problems while setting up Bruin , please refer to the documentation: https://getbruin.com/docs/bruin/getting-started/introduction/installation.html
<br><br>
## Bruin Assets
Create 5 files inside the assets folder that was created with bruin init:
* datalake_ingestion.py
* table_warehouse.sql
* time_view.sql
* distribution_view.sql
* dashboard.asset.yml

![Bruin lineage](https://github.com/davidf552/Videogame_sales/blob/main/images/lineage.png)
[Return](#table-of-contents)


<br><br>


## Step 1: Data Lake
### datalake_ingestion.py
The first part of the pipeline will be downloading the dataset and putting it into the data lake:

```python
"""@bruin
name: datalake_ingestion
description: Ingest video game sales data from Kaggle into a data lake (GCS) 
             using python.
@bruin"""

import kagglehub
from kagglehub import KaggleDatasetAdapter
from google.cloud import storage


def upload_csv(bucket_name, source_file_name, destination_blob_name):
    # Initialize client
    client = storage.Client()

    # Get bucket
    bucket = client.bucket(bucket_name)

    # Create blob (file in bucket)
    blob = bucket.blob(destination_blob_name)

    # Upload file
    blob.upload_from_filename(source_file_name)

    print(f"File {source_file_name} uploaded to {destination_blob_name}.")


# Download latest version

df = kagglehub.dataset_load(
    KaggleDatasetAdapter.PANDAS,
    "bhushandivekar/video-game-sales-and-industry-data-1980-2024",
    "Video_Games_Sales_Cleaned.csv",
)

#Change release_year to int from float to avoid issues with bigquery later on.
df['release_year'] = df['release_year'].astype(int)

#File to local storage
df.to_csv("Video_Games_Sales_Cleaned.csv", index=False)



upload_csv(
    bucket_name="bucket_name",
    source_file_name="Video_Games_Sales_Cleaned.csv",
    destination_blob_name="Video_Games_Sales_Cleaned.csv"
)

```
[Return](#table-of-contents)


<br><br>


## Step 2: Data Warehouse
### table_warehouse.sql
Then, the dataset inside the data lake will go into the data warehouse using the following .sql file:

```hcl
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
  uris = ['gs://bucket_name/Video_Games_Sales_Cleaned.csv'],
  skip_leading_rows = 1
);

```
### Note
* The table is destroyed each year in order to prevent duplicate data.
* The table was clustered and not partitioned, since the current problems to solve will require frequent queries with the console column.

[Return](#table-of-contents)


<br><br>

## Step 3: View Creation
### distribution_view.sql
In order to get the data in a more visual format, you will need to transform the data inside the warehouse:
One of them will be showing each console percentual influence 
```hcl
/* @bruin
name: distribution_view
description: This asset creates a view in BigQuery 
             that calculates the amount of influence of each console.
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

```
### time_view.sql
The other will compute the total sales by release year.

```hcl
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


```

Now, with both views created, you will create the dashboard with Looker Studio. https://lookerstudio.google.com/
* Put BigQuery as a data source and log in when prompted.
* Select the two views just created.
* Create a new report and put each view in a different graph.


<br>



### dashboard.asset.yml
Finally, create a dashboard asset:
```yml
name: dashboard.looker_studio
type: looker
description: "Dashboard sales data visualization: https://lookerstudio.google.com/s/gzHHnAxkZss"

uri: https://lookerstudio.google.com/s/gzHHnAxkZss

depends:
    - time_view
    - distribution_view

tags:
  - dashboard
  - yearly
  - sales


```
<br><br>

### Dashboard
The report for this project is located here: https://lookerstudio.google.com/s/gzHHnAxkZss


[Return](#table-of-contents)


<br><br>


## Pipeline
Once you have done everything from above, run the following command in the terminal:

```bash
bruin run bruin-pipeline

```
Replace bruin-pipeline with the name you have chosen if you have changed it.


That should be it. The pipeline will run once a year and refresh the data in both the lake and warehouse.


![Bruin execution](https://github.com/davidf552/Videogame_sales/blob/main/images/bruin_pipeline.png)

[Return](#table-of-contents)
