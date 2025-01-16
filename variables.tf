variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west2-a"
}

variable "admin_ip_ranges" {
  description = "Admin IP ranges for SSH access"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "SSH Public Keys to SSH into the server"
  type        = string 
}