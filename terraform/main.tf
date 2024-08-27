provider "google" {
  project = "dxc-project-1234"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "my-app-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
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
    ports    = [
      "6443",   # API Server
      "2379",   # etcd
      "2380",   # etcd peer communication
      "10250",  # Kubelet
      "10255",  # Kubelet read-only API
      "10252",  # kube-controller-manager
      "10251",  # kube-scheduler
      "10049",  # kube-proxy
      "30000-32767", # NodePort services
      "80",     # Ingress (HTTP)
      "443",    # Ingress (HTTPS)
      "8080" ,   # Metrics server
      "10443",   # microk8s
      "9093",  #prometheus
      "9090",
      "9100"
    ]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "vm_tooling" {
  name         = "vm-tooling"
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "mouad:${file("~/.ssh/id_ed25519.pub")}"
  }

  tags = ["tooling"]

  
}

resource "google_compute_resource_policy" "daily_schedule" {
  name   = "vm-daily-schedule"
  region = "us-central1"
  description = "Start and stop VM instances during weekdays"

  instance_schedule_policy {
    vm_start_schedule {
      schedule = "45 7 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "15 21 * * 1-5"
    }
    time_zone = "Africa/Casablanca"
  }
}

resource "google_compute_instance" "vm_app" {
  name         = "vm-app"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a"
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
    access_config {
      # Ephemeral public IP
    }
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

# resource "google_compute_resource_policy" "vm_app_schedule" {
#   name   = "vm-app-schedule"
#   region = "us-central1"
  
#   instance_schedule_policy {
#     vm_start_schedule {
#       schedule = "45 7 * * 1-5"
#     }
#     vm_stop_schedule {
#       schedule = "45 14 * * 1-5"
#     }
#     time_zone = "Africa/Casablanca"
#   }
# }

# resource "google_compute_instance_resource_policy_attachment" "vm_app_schedule_attachment" {
#   instance = google_compute_instance.vm_app.name
#   resource_policy = google_compute_resource_policy.vm_app_schedule.id
#   zone = "us-central1-a"
# }

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