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

resource "google_compute_instance" "vm_tooling" {
  name         = "vm-tooling"
  machine_type = "e2-medium"
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

  # Copy Ansible files to vm-tooling
  provisioner "file" {
    source      = "../ansible"
    destination = "/home/mouad/ansible"
    
    connection {
      type        = "ssh"
      user        = "mouad"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Copy GCP service account key to vm-tooling
  provisioner "file" {
    source      = "/home/mouad/dxc-project-1234-c9724e72a3cc.json"
    destination = "/home/mouad/gcp-key.json"
    
    connection {
      type        = "ssh"
      user        = "mouad"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
  provisioner "remote-exec" {
  inline = [
    "mkdir -p /home/mouad/Desktop/Appv2",
    "chmod -R 755 /home/mouad/Desktop/Appv2",
    "chown -R mouad:mouad /home/mouad/Desktop/Appv2"
  ]
  
  connection {
    type        = "ssh"
    user        = "mouad"
    private_key = file("~/.ssh/id_ed25519")
    host        = self.network_interface[0].access_config[0].nat_ip
  }
}
  provisioner "file" {
    source      = "/home/mouad/Desktop/Appv2"
    destination = "/home/mouad/Desktop"
    
    connection {
      type        = "ssh"
      user        = "mouad"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
provisioner "remote-exec" {
    inline = [
      "chmod -R 755 /home/mouad/Desktop/Appv2",
      "chown -R mouad:mouad /home/mouad/Desktop/Appv2"
    ]
    
    connection {
      type        = "ssh"
      user        = "mouad"
      private_key = file("~/.ssh/id_ed25519")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Install Ansible, set up GCP inventory, and run playbooks
provisioner "remote-exec" {
  inline = [
    "set -e",
    "sudo apt-get update || (echo 'apt-get update failed' && exit 1)",
    "sudo apt-get install -y software-properties-common apt-transport-https ca-certificates curl gnupg || (echo 'Failed to install prerequisites' && exit 1)",
    "sudo add-apt-repository --yes --update ppa:ansible/ansible || (echo 'Failed to add Ansible repo' && exit 1)",
    
    # Install Ansible and Python packages
    "sudo apt-get install -y ansible python3-pip || (echo 'Failed to install Ansible and pip' && exit 1)",
    "pip3 install --user google-auth requests || (echo 'Failed to install Python packages' && exit 1)",
    "sudo usermod -aG docker mouad",
    "newgrp docker",
    "ls -l /var/run/docker.sock || echo 'Docker socket not found'",
    
    # Install Kubernetes components (updated for new repository)
    "sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || (echo 'Failed to download Kubernetes GPG key' && exit 1)",
    "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list || (echo 'Failed to add Kubernetes repo' && exit 1)",
    "sudo apt-get update || (echo 'Failed to update apt after adding Kubernetes repo' && exit 1)",
    "sudo apt-get install -y kubelet kubeadm kubectl || (echo 'Failed to install Kubernetes components' && exit 1)",
    "sudo apt-mark hold kubelet kubeadm kubectl || (echo 'Failed to hold Kubernetes components' && exit 1)",
    "sudo systemctl restart kubelet || (echo 'Failed to restart kubelet service' && exit 1)",
    "pip3 install --user kubernetes openshift",

    
    # Install Docker
    "sudo apt-get install -y docker.io || (echo 'Failed to install Docker' && exit 1)",
    "sudo systemctl enable docker || (echo 'Failed to enable Docker' && exit 1)",
    "sudo systemctl start docker || (echo 'Failed to start Docker' && exit 1)",
    "sudo usermod -aG docker mouad",
    "newgrp docker",
    "ls -l /var/run/docker.sock || echo 'Docker socket not found'",
    # Add local bin to PATH
    "echo 'export PATH=$PATH:$HOME/.local/bin' >> $HOME/.bashrc",
    "export PATH=$PATH:$HOME/.local/bin",
    
    # Debug commands
    "echo 'Current PATH: $PATH'",
    "which ansible-galaxy || echo 'ansible-galaxy not found'",
    "which ansible-playbook || echo 'ansible-playbook not found'",
    "ls -l /usr/bin/ansible* || echo 'No Ansible binaries found in /usr/bin'",
    
    # Install Ansible collection
    "ansible-galaxy collection install google.cloud || (echo 'Failed to install Ansible collection' && exit 1)",
    "ansible-galaxy collection install kubernetes.core",
    "ansible-galaxy collection install community.general",
    "ansible-galaxy collection install community.docker",
    
    # Set up GCP service account
    "echo 'export GCP_SERVICE_ACCOUNT_FILE=/home/mouad/gcp-key.json' >> $HOME/.bashrc",
    "export GCP_SERVICE_ACCOUNT_FILE=/home/mouad/gcp-key.json",
    # Install kubectl
    "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
    "chmod +x kubectl",
    "sudo mv kubectl /usr/local/bin/",
    
    # Install ArgoCD CLI
    "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64",
    "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",
    "rm argocd-linux-amd64",
    
    # Run Ansible playbook
    "cd /home/mouad/ansible || (echo 'Failed to change directory' && exit 1)",
    "ansible-playbook main.yml -vvv || (echo 'Failed to run Ansible playbook' && exit 1)"
  ]
  
  connection {
    type        = "ssh"
    user        = "mouad"
    private_key = file("~/.ssh/id_ed25519")
    host        = self.network_interface[0].access_config[0].nat_ip
  }
}
}

resource "google_compute_instance" "vm_app" {
  name         = "vm-app"
  machine_type = "e2-medium"
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

  tags = ["app"]
}

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