resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_16"

  settings {
    tier              = "db-custom-1-3840"
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_size         = 20
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = true
}

resource "google_sql_database" "app" {
  name     = var.db_name
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.postgres.name
  name     = var.db_user
  password = var.db_password
}
