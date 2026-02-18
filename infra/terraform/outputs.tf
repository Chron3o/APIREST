output "cloud_run_url" {
  value = module.run.service_url
}

output "lb_ip_address" {
  value = module.edge.lb_ip_address
}

output "pubsub_topic" {
  value = module.jobs.topic_name
}

output "pubsub_subscription" {
  value = module.jobs.subscription_name
}
