variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "dxc-project-1234"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
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