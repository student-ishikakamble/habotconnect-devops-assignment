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

# =========================================================
# D0 - RAW LANDING BUCKET
# Secure Google Cloud Storage bucket for raw landing data
# =========================================================

resource "google_storage_bucket" "d0_raw_landing" {
  name                        = "${var.project_id}-d0-raw-landing"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = "${var.project_id}-d0-access-logs"
    log_object_prefix = "raw-landing/"
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

# =========================================================
# D0 - ACCESS LOGGING BUCKET
# Dedicated destination for Cloud Storage access logs
# =========================================================

#checkov:skip=CKV_GCP_62
resource "google_storage_bucket" "d0_access_logs" {
  name                        = "${var.project_id}-d0-access-logs"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }

    action {
      type = "Delete"
    }
  }
}

# =========================================================
# D1 - STAGED / ENFORCED BIGQUERY DATASET
# =========================================================

resource "google_bigquery_dataset" "d1_staged_enforced" {
  dataset_id = "d1_staged_enforced"
  location   = var.region

  delete_contents_on_destroy = false

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.bigquery_key.id
  }
}

# =========================================================
# KMS - ENCRYPTION KEY FOR BIGQUERY
# =========================================================

resource "google_kms_key_ring" "habotconnect_key_ring" {
  name     = "habotconnect-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "bigquery_key" {
  name            = "bigquery-d1-key"
  key_ring        = google_kms_key_ring.habotconnect_key_ring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

# =========================================================
# SERVICE ACCOUNTS
# Terraform-managed identities
# =========================================================

resource "google_service_account" "ingestion" {
  account_id   = "habot-ingestion"
  display_name = "HabotConnect D0 Ingestion Service Account"
  description  = "Service account for controlled ingestion into the D0 raw landing layer."
}

resource "google_service_account" "analytics" {
  account_id   = "habot-analytics"
  display_name = "HabotConnect D1 Analytics Service Account"
  description  = "Service account for controlled analytics access to the D1 staged dataset."
}

# =========================================================
# LEAST-PRIVILEGE IAM - D0
# Ingestion can create objects but cannot modify or delete
# existing objects.
# =========================================================

resource "google_storage_bucket_iam_member" "d0_raw_landing_object_creator" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.ingestion.email}"

  condition {
    title       = "Restrict ingestion to D0 raw landing objects"
    description = "Allows the ingestion service account to create objects only in the D0 raw landing bucket."
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.project_id}-d0-raw-landing/objects/\")"
  }
}

# =========================================================
# LEAST-PRIVILEGE IAM - D1
# Analytics service account is restricted to the D1 dataset.
# =========================================================

resource "google_bigquery_dataset_iam_member" "d1_data_editor" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.analytics.email}"

  condition {
    title       = "Restrict analytics access to D1 dataset"
    description = "Allows the analytics service account to manage data only within the D1 staged dataset."
    expression  = "resource.name == \"projects/${var.project_id}/datasets/d1_staged_enforced\""
  }
}