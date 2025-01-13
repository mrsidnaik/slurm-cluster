output "login_node_ip" {
  value = google_compute_instance.login_node.network_interface[0].access_config[0].nat_ip
}

output "filestore_ip" {
  value = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
}

output "compute_node_internal_ip" {
  value = google_compute_instance.compute_node.network_interface[0].network_ip
}

output "gpu_node_internal_ip" {
  value = google_compute_instance.gpu_node.network_interface[0].network_ip
}