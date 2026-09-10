variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "habotconnect-ishika-2026-0910"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-south1"
}

variable "ingestion_service_account" {
  description = "Service account used for raw landing data ingestion"
  type        = string
}

variable "analytics_service_account" {
  description = "Service account used for staged analytics data"
  type        = string
}