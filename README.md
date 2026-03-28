#  Data Engineering Zoomcamp 2026 Capstone Project Videogame_sales

## Introduction
Which gaming consoles are popular? What about the revenue they attract?
These questions and more can be resolved with: DATA.
It is important to get up-to-date information regarding sales and the public's perception about which console is the best.

In this project: 
* A yearly report about videogame sales will be transported from its source to Google Cloud Storage GCS (data lake).
* From GCS, it will go into Google BigQuery (data warehouse).
* Inside BigQuery, two transformations will take place and create two different Views, where Looker Studio (dashboard) will present them in a graphical manner.

How will these 3 steps be executed? It can be done manually one at a time, but there is a better way: a data pipeline.
Bruin will be the data platform employed to build all the above and in simple steps.

## Setup
### Google Cloud Services
* You will need a GC account for this project: https://cloud.google.com/
* After you get one, create a new project and a service account with the following permissions: BigQuery Admin and Storage Admin.
* Generate the service keys and download the json file. Keep it in a safe place.
* Take note of the project ID

### Terraform
You will need to download and install Terraform in order to prepare the data lake and data warehouse for the pipeline. https://developer.hashicorp.com/terraform

Also, be sure it is on the system's PATH.

### VSCode
This project was made using VSCode with Bruin. Create a new project in the directory of your choice.

### Bruin
Install Bruin: One way is using the Git Bash terminal inside VSCode
```bash
curl -LsSf https://getbruin.com/install/cli | sh

```
If it doesn't work, check the following link for more detailed instructions: https://getbruin.com/docs/bruin/getting-started/introduction/installation.html

Once installed, it is recommended to get the Bruin VSCode extension. You can find it on the extensions tab inside VSCode.

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
  name          = "bruin-test-001"
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
