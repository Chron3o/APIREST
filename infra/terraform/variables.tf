variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "service_name" {
  type    = string
  default = "security-api"
}

variable "container_image" {
  type = string
}

variable "db_instance_name" {
  type    = string
  default = "security-api-pg"
}

variable "db_name" {
  type    = string
  default = "security_api"
}

variable "db_user" {
  type    = string
  default = "api_user"
}

variable "db_password_secret_id" {
  type    = string
  default = "db-password"
}

variable "iap_client_id" {
  type = string
}

variable "iap_client_secret_secret_id" {
  type    = string
  default = "iap-client-secret"
}

variable "nvd_api_key_secret_id" {
  type    = string
  default = "nvd-api-key"
}

variable "database_url_secret_id" {
  type    = string
  default = "database-url"
}

variable "domain_name" {
  type = string
}

variable "operator_group_email" {
  type = string
}

variable "scheduler_cron" {
  type    = string
  default = "*/30 * * * *"
}

variable "scheduler_timezone" {
  type    = string
  default = "UTC"
}

variable "http_timeout_seconds" {
  type    = number
  default = 20
}

variable "nvd_results_per_page" {
  type    = number
  default = 500
}

variable "nvd_max_pages" {
  type    = number
  default = 3
}
