terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------
# D0 - Raw Landing
# Secure Google Cloud Storage bucket for raw landing data
# ---------------------------------------------------------

resource "google_storage_bucket" "d0_raw_landing" {
  name                        = "${var.project_id}-d0-raw-landing"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }

    action {
      type = "Delete"
    }
  }
}

# ---------------------------------------------------------
# D1 - Staged / Enforced
# BigQuery dataset for validated and staged data
# ---------------------------------------------------------

resource "google_bigquery_dataset" "d1_staged_enforced" {
  dataset_id = "d1_staged_enforced"
  location   = var.region

  delete_contents_on_destroy = false
}
# ---------------------------------------------------------
# Security / Least Privilege
# Assignment: HabotConnect FZCO
# ---------------------------------------------------------

resource "google_storage_bucket_iam_member" "d0_raw_landing_object_viewer" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.ingestion_service_account}"
}

resource "google_bigquery_dataset_iam_member" "d1_data_editor" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.analytics_service_account}"
}