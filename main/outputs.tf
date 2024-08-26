output "tooling_vm_ip" {
  value       = google_compute_instance.vm_tooling.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the tooling VM"
}

output "app_vm_ip" {
  value       = google_compute_instance.vm_app.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the app VM"
}