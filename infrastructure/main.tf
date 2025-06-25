terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "bacon13"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "firestore.googleapis.com",
    "firebase.googleapis.com",
    "identitytoolkit.googleapis.com",
    "storage.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
}

# Firestore database
resource "google_firestore_database" "main" {
  project                     = var.project_id
  name                        = "(default)"
  location_id                 = var.region
  type                        = "FIRESTORE_NATIVE"
  delete_protection_state     = "DELETE_PROTECTION_DISABLED"
  deletion_policy             = "DELETE"

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage bucket for image uploads
resource "google_storage_bucket" "images_bucket" {
  name     = "bacon13-app-images-${var.project_id}-${var.environment}"
  location = var.region
  
  uniform_bucket_level_access = true
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make bucket publicly readable for image serving
resource "google_storage_bucket_iam_binding" "images_bucket_public_read" {
  bucket = google_storage_bucket.images_bucket.name
  role   = "roles/storage.objectViewer"
  
  members = [
    "allUsers",
  ]
}

# No service accounts needed - frontend uses Firebase SDK with user authentication

# No Cloud Run services needed - frontend communicates directly with Firebase

# Outputs

output "firestore_database_name" {
  description = "Firestore database name"
  value = google_firestore_database.main.name
}

output "storage_bucket_name" {
  description = "Cloud Storage bucket name"
  value = google_storage_bucket.images_bucket.name
}
