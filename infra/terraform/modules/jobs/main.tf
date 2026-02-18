resource "google_pubsub_topic" "cve_sync" {
  project = var.project_id
  name    = "cve-sync-topic"
}

resource "google_pubsub_topic" "cve_sync_dlq" {
  project = var.project_id
  name    = "cve-sync-dlq-topic"
}

resource "google_pubsub_subscription" "cve_sync_pull" {
  project = var.project_id
  name    = "cve-sync-subscription"
  topic   = google_pubsub_topic.cve_sync.id

  ack_deadline_seconds = 30

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.cve_sync_dlq.id
    max_delivery_attempts = 10
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_project_iam_member" "scheduler_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

resource "google_cloud_scheduler_job" "cve_sync" {
  project   = var.project_id
  region    = var.region
  name      = "cve-sync-scheduler"
  schedule  = var.scheduler_cron
  time_zone = var.scheduler_timezone

  pubsub_target {
    topic_name = google_pubsub_topic.cve_sync.id
    data       = base64encode("{\"action\":\"sync_nvd\"}")
  }
}
