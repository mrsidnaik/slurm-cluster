# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Network resources
resource "google_compute_network" "slurm_network" {
  name                    = "slurm-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "slurm_subnet" {
  name          = "slurm-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.slurm_network.id
}

# Firewall rules
resource "google_compute_firewall" "slurm_login" {
  name    = "slurm-login"
  network = google_compute_network.slurm_network.id

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "6817-6819"]
  }

  source_ranges = var.admin_ip_ranges
  target_tags   = ["login-node"]
}

# Filestore instance
resource "google_filestore_instance" "slurm_storage" {
  name     = "slurm-storage"
  location = var.zone
  tier     = "BASIC_HDD"

  file_shares {
    name        = "nfs1"
    capacity_gb = 1024
  }

  networks {
    network = google_compute_network.slurm_network.name
    modes   = ["MODE_IPV4"]
  }
}

# Compute instances
resource "google_compute_instance" "login_node" {
  name         = "login-node"
  machine_type = "n2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-8"
      size  = 100
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.slurm_subnet.id
    access_config {} # Enables external IP
  }

  metadata = {
    ssh-keys = "admin:ssh-rsa ---- BEGIN SSH2 PUBLIC KEY ----
Comment: "rsa-key-20250113"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCsdQFzBXSMqLP3KpwC0EvR4hhC1KDCDGO+
XuemH+TM3XWhL9gYgKZQu1ocgd7F7yiJik0TBPUJ/ahSS5Uw4ditZofJgU4Wsk/M
o2sa/WQp4aOSoOMwEqwD0EZlnBOD629lXwtPxfiGGdqt5du8ZaB66zJfgt6rNmSd
ObPS0TAN7GhPVHWPhJdfyhxx8hcjSop9krSXF8px5VCrC+x9Y6TzY5sx5XDLh0gw
AHclDfDTx430BK+ZFmJhWJ+XrCzCOBV0G5xNgSqw/Ju8X9Pju3UlF1M5YKVDFaRA
jZyC4FcHejcrUh6XnurJk3arHvI/WoEjET/r9Tjxw3bBbA5jT7Hd
---- END SSH2 PUBLIC KEY ----
"
  }

  tags = ["login-node", "slurm-cluster"]

  metadata_startup_script = templatefile("${path.module}/scripts/startup-login.sh", {
    filestore_ip = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
  })
}

resource "google_compute_instance" "compute_node" {
  name         = "compute-node"
  machine_type = "c2-standard-8"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-8"
      size  = 100
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.slurm_subnet.id
  }

  metadata = {
    ssh-keys = "admin:ssh-rsa ---- BEGIN SSH2 PUBLIC KEY ----
Comment: "rsa-key-20250113"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCsdQFzBXSMqLP3KpwC0EvR4hhC1KDCDGO+
XuemH+TM3XWhL9gYgKZQu1ocgd7F7yiJik0TBPUJ/ahSS5Uw4ditZofJgU4Wsk/M
o2sa/WQp4aOSoOMwEqwD0EZlnBOD629lXwtPxfiGGdqt5du8ZaB66zJfgt6rNmSd
ObPS0TAN7GhPVHWPhJdfyhxx8hcjSop9krSXF8px5VCrC+x9Y6TzY5sx5XDLh0gw
AHclDfDTx430BK+ZFmJhWJ+XrCzCOBV0G5xNgSqw/Ju8X9Pju3UlF1M5YKVDFaRA
jZyC4FcHejcrUh6XnurJk3arHvI/WoEjET/r9Tjxw3bBbA5jT7Hd
---- END SSH2 PUBLIC KEY ----
"
  }

  tags = ["compute-node", "slurm-cluster"]

  metadata_startup_script = templatefile("${path.module}/scripts/startup-compute.sh", {
    filestore_ip = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
  })
}

resource "google_compute_instance" "gpu_node" {
  name         = "gpu-node"
  machine_type = "g2-standard-12"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-8"
      size  = 100
    }
  }

  guest_accelerator {
    type  = "projects/imcm-candidate-test/zones/europe-west2-a/acceleratorTypes/nvidia-l4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.slurm_subnet.id
  }

  metadata = {
    ssh-keys = "admin:ssh-rsa ---- BEGIN SSH2 PUBLIC KEY ----
Comment: "rsa-key-20250113"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCsdQFzBXSMqLP3KpwC0EvR4hhC1KDCDGO+
XuemH+TM3XWhL9gYgKZQu1ocgd7F7yiJik0TBPUJ/ahSS5Uw4ditZofJgU4Wsk/M
o2sa/WQp4aOSoOMwEqwD0EZlnBOD629lXwtPxfiGGdqt5du8ZaB66zJfgt6rNmSd
ObPS0TAN7GhPVHWPhJdfyhxx8hcjSop9krSXF8px5VCrC+x9Y6TzY5sx5XDLh0gw
AHclDfDTx430BK+ZFmJhWJ+XrCzCOBV0G5xNgSqw/Ju8X9Pju3UlF1M5YKVDFaRA
jZyC4FcHejcrUh6XnurJk3arHvI/WoEjET/r9Tjxw3bBbA5jT7Hd
---- END SSH2 PUBLIC KEY ----
"
  }

  tags = ["gpu-node", "slurm-cluster"]

  metadata_startup_script = templatefile("${path.module}/scripts/startup-gpu.sh", {
    filestore_ip = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
  })
}

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