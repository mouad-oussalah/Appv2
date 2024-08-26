resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "kubernetes_ports" {
  name    = "kubernetes-ports"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = local.kubernetes_ports
  }

  source_ranges = ["0.0.0.0/0"]
}