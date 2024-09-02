resource "google_compute_instance" "vm_tooling" {
  name         = "vm-tooling"
  machine_type = "n2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50 
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata = {
    ssh-keys = "mouad:${file("~/.ssh/id_ed25519.pub")}"
  }

  tags = ["tooling"]
}

resource "google_compute_instance" "vm_app" {
  name         = "vm-app"
  machine_type = "e2-standard-4"
  zone         = var.zone
  resource_policies = [google_compute_resource_policy.daily_schedule.id]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50  
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata = {
    ssh-keys = "mouad:${file("~/.ssh/id_ed25519.pub")}"
    startup-script = file("${path.module}/startup.sh")
    shutdown-script = file("${path.module}/shutdown.sh")
  }

  tags = ["app"]

  scheduling {
    preemptible = false
    automatic_restart = false
    on_host_maintenance = "MIGRATE"
  }
}