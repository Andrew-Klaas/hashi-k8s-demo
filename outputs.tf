output "k8s_endpoint" {
  value = google_container_cluster.k8sexample.endpoint
}

output "gcloud_connect_command" {
  value = "gcloud container clusters get-credentials var.cluster_name --zone var.gcp_zone --project var.gcp_project"
}
