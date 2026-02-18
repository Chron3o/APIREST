output "topic_name" {
  value = google_pubsub_topic.cve_sync.name
}

output "subscription_name" {
  value = google_pubsub_subscription.cve_sync_pull.name
}
