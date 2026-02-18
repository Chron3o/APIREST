resource "google_cloud_run_v2_service" "api" {
  project  = var.project_id
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.runtime_service_account_email
    timeout         = "300s"
    annotations = {
      "run.googleapis.com/cloudsql-instances" = var.connection_name
    }

    containers {
      image = var.container_image

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = var.database_url_secret_name
            version = "latest"
          }
        }
      }

      env {
        name = "NVD_API_KEY"
        value_source {
          secret_key_ref {
            secret  = var.nvd_api_key_secret_name
            version = "latest"
          }
        }
      }

      env {
        name  = "HTTP_TIMEOUT_SECONDS"
        value = tostring(var.http_timeout_seconds)
      }

      env {
        name  = "NVD_RESULTS_PER_PAGE"
        value = tostring(var.nvd_results_per_page)
      }

      env {
        name  = "NVD_MAX_PAGES"
        value = tostring(var.nvd_max_pages)
      }
    }
  }
}
