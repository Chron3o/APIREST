resource "google_service_account" "api_runtime" {
  project      = var.project_id
  account_id   = "${var.service_name}-runtime"
  display_name = "Runtime SA for ${var.service_name}"
}

resource "google_project_iam_member" "api_runtime_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.api_runtime.email}"
}

data "google_secret_manager_secret_version" "db_password" {
  project = var.project_id
  secret  = var.db_password_secret_id
  version = "latest"

  depends_on = [google_project_service.required["secretmanager.googleapis.com"]]
}

data "google_secret_manager_secret_version" "iap_client_secret" {
  project = var.project_id
  secret  = var.iap_client_secret_secret_id
  version = "latest"

  depends_on = [google_project_service.required["secretmanager.googleapis.com"]]
}

module "sql" {
  source        = "./modules/sql"
  project_id    = var.project_id
  region        = var.region
  instance_name = var.db_instance_name
  db_name       = var.db_name
  db_user       = var.db_user
  db_password   = data.google_secret_manager_secret_version.db_password.secret_data

  depends_on = [google_project_service.required]
}

locals {
  database_url = "host=/cloudsql/${module.sql.connection_name} user=${var.db_user} password=${data.google_secret_manager_secret_version.db_password.secret_data} dbname=${var.db_name} sslmode=disable"
}

module "secrets" {
  source                        = "./modules/secrets"
  project_id                    = var.project_id
  database_url_secret_id        = var.database_url_secret_id
  nvd_api_key_secret_id         = var.nvd_api_key_secret_id
  database_url                  = local.database_url
  runtime_service_account_email = google_service_account.api_runtime.email

  depends_on = [google_project_service.required]
}

module "run" {
  source                        = "./modules/run"
  project_id                    = var.project_id
  region                        = var.region
  service_name                  = var.service_name
  container_image               = var.container_image
  runtime_service_account_email = google_service_account.api_runtime.email
  connection_name               = module.sql.connection_name
  database_url_secret_name      = module.secrets.database_url_secret_name
  nvd_api_key_secret_name       = module.secrets.nvd_api_key_secret_name
  http_timeout_seconds          = var.http_timeout_seconds
  nvd_results_per_page          = var.nvd_results_per_page
  nvd_max_pages                 = var.nvd_max_pages

  depends_on = [
    module.sql,
    module.secrets,
    google_project_iam_member.api_runtime_cloudsql_client
  ]
}

module "edge" {
  source               = "./modules/edge"
  project_id           = var.project_id
  region               = var.region
  service_name         = module.run.service_name
  domain_name          = var.domain_name
  iap_client_id        = var.iap_client_id
  iap_client_secret    = data.google_secret_manager_secret_version.iap_client_secret.secret_data
  operator_group_email = var.operator_group_email

  depends_on = [module.run]
}

module "jobs" {
  source             = "./modules/jobs"
  project_id         = var.project_id
  region             = var.region
  scheduler_cron     = var.scheduler_cron
  scheduler_timezone = var.scheduler_timezone

  depends_on = [google_project_service.required]
}
