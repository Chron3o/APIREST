output "connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "db_name" {
  value = google_sql_database.app.name
}

output "db_user" {
  value = google_sql_user.app.name
}
