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
  default     = "seenem"
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
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
}

# Cloud SQL instance for PostgreSQL
resource "google_sql_database_instance" "main" {
  name             = "seenem-app-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false

  depends_on = [google_project_service.required_apis]

  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
  }
}

resource "google_sql_database" "database" {
  name     = "seenem_app"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "user" {
  name     = "app_user"
  instance = google_sql_database_instance.main.name
  password = "secure_password_change_in_prod"
}

# Cloud Storage bucket for image uploads
resource "google_storage_bucket" "images_bucket" {
  name     = "seenem-app-images-${var.project_id}-${var.environment}"
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

# Service Account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  account_id   = "seenem-cloud-run-sa"
  display_name = "Seenem App Cloud Run Service Account"
  
  depends_on = [google_project_service.required_apis]
}

# IAM bindings for the service account
resource "google_project_iam_binding" "cloud_run_sa_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  
  members = [
    "serviceAccount:${google_service_account.cloud_run_sa.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "images_bucket_admin" {
  bucket = google_storage_bucket.images_bucket.name
  role   = "roles/storage.objectAdmin"
  
  members = [
    "serviceAccount:${google_service_account.cloud_run_sa.email}",
  ]
}

# Cloud Run services
locals {
  services = {
    "user-service" = {
      port = 8080
      cpu = "1000m"
      memory = "512Mi"
    }
    "auth-service" = {
      port = 8081
      cpu = "1000m"
      memory = "512Mi"
    }
    "post-service" = {
      port = 8082
      cpu = "1000m"
      memory = "512Mi"
    }
  }
}

resource "google_cloud_run_service" "services" {
  for_each = local.services
  
  name     = each.key
  location = var.region

  depends_on = [google_project_service.required_apis]

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "autoscaling.knative.dev/minScale" = "0"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.main.connection_name
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }

    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.project_id}/${each.key}:latest"
        
        ports {
          container_port = each.value.port
        }

        env {
          name  = "PORT"
          value = tostring(each.value.port)
        }

        env {
          name  = "DB_HOST"
          value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
        }

        env {
          name  = "DB_NAME"
          value = google_sql_database.database.name
        }

        env {
          name  = "DB_USER"
          value = google_sql_user.user.name
        }

        env {
          name  = "DB_PASSWORD"
          value = google_sql_user.user.password
        }

        env {
          name  = "STORAGE_BUCKET"
          value = google_storage_bucket.images_bucket.name
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }

        # Service-specific environment variables
        dynamic "env" {
          for_each = each.key == "user-service" ? [1] : []
          content {
            name  = "AUTH_SERVICE_URL"
            value = "https://${google_cloud_run_service.services["auth-service"].status[0].url}"
          }
        }

        dynamic "env" {
          for_each = each.key == "post-service" ? [1] : []
          content {
            name  = "USER_SERVICE_URL"
            value = "https://${google_cloud_run_service.services["user-service"].status[0].url}"
          }
        }

        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# IAM policy to allow public access (adjust as needed)
resource "google_cloud_run_service_iam_binding" "public_access" {
  for_each = local.services
  
  location = google_cloud_run_service.services[each.key].location
  service  = google_cloud_run_service.services[each.key].name
  role     = "roles/run.invoker"
  
  members = [
    "allUsers",
  ]
}

# Outputs
output "service_urls" {
  description = "URLs of the deployed Cloud Run services"
  value = {
    for service_name, service in google_cloud_run_service.services :
    service_name => service.status[0].url
  }
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value = google_sql_database_instance.main.connection_name
}

output "storage_bucket_name" {
  description = "Cloud Storage bucket name"
  value = google_storage_bucket.images_bucket.name
}

output "database_ip" {
  description = "Database IP address"
  value = google_sql_database_instance.main.ip_address[0].ip_address
}
