data "google_compute_instance" "vm_tooling" {
  name = google_compute_instance.vm_tooling.name
  zone = google_compute_instance.vm_tooling.zone
}

data "google_compute_instance" "vm_app" {
  name = google_compute_instance.vm_app.name
  zone = google_compute_instance.vm_app.zone
}

output "tooling_vm_ip" {
  value = data.google_compute_instance.vm_tooling.network_interface[0].access_config[0].nat_ip
}

output "app_vm_ip" {
  value = data.google_compute_instance.vm_app.network_interface[0].access_config[0].nat_ip
}