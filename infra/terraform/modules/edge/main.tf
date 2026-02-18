locals {
  neg_name          = "${var.service_name}-neg"
  backend_name      = "${var.service_name}-backend"
  url_map_name      = "${var.service_name}-url-map"
  https_proxy_name  = "${var.service_name}-https-proxy"
  forwarding_name   = "${var.service_name}-https-fr"
  ssl_cert_name     = "${var.service_name}-cert"
  armor_policy_name = "${var.service_name}-waf"
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = local.neg_name
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.service_name
  }
}

resource "google_compute_security_policy" "waf" {
  project = var.project_id
  name    = local.armor_policy_name

  rule {
    priority = 1000
    action   = "deny(403)"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable') || evaluatePreconfiguredWaf('xss-v33-stable')"
      }
    }
    description = "Block common SQL injection and XSS payloads"
  }

  rule {
    priority = 2147483647
    action   = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow"
  }
}

resource "google_compute_backend_service" "backend" {
  project               = var.project_id
  name                  = local.backend_name
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.waf.id

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  iap {
    enabled              = true
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = local.ssl_cert_name

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_url_map" "url_map" {
  project         = var.project_id
  name            = local.url_map_name
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project          = var.project_id
  name             = local.https_proxy_name
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

resource "google_compute_global_forwarding_rule" "https_rule" {
  project               = var.project_id
  name                  = local.forwarding_name
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_iap_web_backend_service_iam_member" "operator_access" {
  project             = var.project_id
  web_backend_service = google_compute_backend_service.backend.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "group:${var.operator_group_email}"
}
