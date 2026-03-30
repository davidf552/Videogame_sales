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
    bucket_name="",
    source_file_name="Video_Games_Sales_Cleaned.csv",
    destination_blob_name="Video_Games_Sales_Cleaned.csv"
)
