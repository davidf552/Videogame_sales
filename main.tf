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

resource "google_storage_bucket" "bruin_bucket" {
  name          = "bucket_name"
  location      = "us-east4"

}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "game_sales"
  location   = "us-east4"
}
