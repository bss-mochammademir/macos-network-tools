terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "bss-sandbox-project-1"
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "asia-southeast2"
}

# Storage Bucket to store Cloud Function source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-gcf-source"
  location = var.region
  uniform_bucket_level_access = true
}

# Zip the function code
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../../backend/functions"
  output_path = "/tmp/function.zip"
}

# Upload source code to bucket
resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"
  name         = "src-${data.archive_file.source.output_md5}.zip"
  bucket       = google_storage_bucket.function_bucket.name
}

# Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "get_policy" {
  name        = "get-policy"
  location    = var.region
  description = "NetPulse Policy Provider"

  build_config {
    runtime     = "nodejs20"
    entry_point = "getPolicy"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

# Allow unauthenticated access (for initial testing only, usually lock this down)
resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.get_policy.location
  service  = google_cloudfunctions2_function.get_policy.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "function_uri" {
  value = google_cloudfunctions2_function.get_policy.service_config[0].uri
}
