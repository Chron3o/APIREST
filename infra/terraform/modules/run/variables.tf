variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "runtime_service_account_email" {
  type = string
}

variable "connection_name" {
  type = string
}

variable "database_url_secret_name" {
  type = string
}

variable "nvd_api_key_secret_name" {
  type = string
}

variable "http_timeout_seconds" {
  type = number
}

variable "nvd_results_per_page" {
  type = number
}

variable "nvd_max_pages" {
  type = number
}
