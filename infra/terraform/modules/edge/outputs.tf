output "lb_ip_address" {
  value = google_compute_global_forwarding_rule.https_rule.ip_address
}

output "backend_service_name" {
  value = google_compute_backend_service.backend.name
}
