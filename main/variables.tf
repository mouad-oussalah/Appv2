variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "dxc-project-1234"
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "my-app-network"
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
  default     = "my-app-subnet"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_username" {
  description = "The username for SSH access"
  type        = string
  default     = "mouad"
}

variable "ssh_pub_key_path" {
  description = "The path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}