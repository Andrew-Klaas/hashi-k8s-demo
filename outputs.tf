/*
//K8s Cluster
output "k8s_endpoint" {
  value = "${google_container_cluster.k8sexample.endpoint}"
}
output "k8s_master_version" {
  value = "${google_container_cluster.k8sexample.master_version}"
}
output "k8s_instance_group_urls" {
  value = "${google_container_cluster.k8sexample.instance_group_urls.0}"
}
output "k8s_master_auth_client_certificate" {
  value = "${google_container_cluster.k8sexample.master_auth.0.client_certificate}"
}
output "k8s_master_auth_client_key" {
  value = "${google_container_cluster.k8sexample.master_auth.0.client_key}"
}
output "k8s_master_auth_cluster_ca_certificate" {
  value = "${google_container_cluster.k8sexample.master_auth.0.cluster_ca_certificate}"
}
*/

// Auth to k8s cluster 
output "gcloud_connect_command" {
  value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.gcp_zone} --project ${var.gcp_project}"
}


// MariaDB
output "ip" {
 value = "${google_compute_instance.mariadb.network_interface.0.access_config.0.nat_ip}"
}
output "private_ip" {
 value = "${google_compute_instance.mariadb.network_interface.0.network_ip}"
}