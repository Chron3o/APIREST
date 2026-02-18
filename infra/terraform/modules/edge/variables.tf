variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "iap_client_id" {
  type = string
}

variable "iap_client_secret" {
  type      = string
  sensitive = true
}

variable "operator_group_email" {
  type = string
}
