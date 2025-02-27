# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Network resources configuration
resource "google_compute_network" "slurm_network" {
  name                    = "slurm-network"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"  
}

resource "google_compute_subnetwork" "slurm_subnet" {
  name          = "slurm-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.slurm_network.id
  
  # Enable private Google access
  private_ip_google_access = true
}

# Firewall rules
# 1. Allow SSH from admin IPs
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.slurm_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.admin_ip_ranges
  target_tags   = ["login-node"]
}

# 2. Allow Slurm ports
resource "google_compute_firewall" "allow_slurm" {
  name    = "allow-slurm"
  network = google_compute_network.slurm_network.id

  allow {
    protocol = "tcp"
    ports    = ["6817-6819"]
  }

  source_tags = ["slurm-cluster"]
  target_tags = ["slurm-cluster"]
}

# 3. Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.slurm_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/24"]  # Matches subnet CIDR
}

# 4. Allow NFS traffic
resource "google_compute_firewall" "allow_nfs" {
  name    = "allow-nfs"
  network = google_compute_network.slurm_network.id

  allow {
    protocol = "tcp"
    ports    = ["111", "2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["111", "2049"]
  }

  source_tags = ["slurm-cluster"]
  target_tags = ["slurm-cluster"]
}

# Nat configuration
resource "google_compute_router_nat" "nat" {
  name                               = "slurm-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Cloud router
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "slurm-router"
  network = google_compute_network.slurm_network.name
  region  = var.region
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
    ssh-keys = var.ssh_public_key
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
    #access_config {} # Enables external IP
  }

  tags = ["compute-node", "slurm-cluster"]

  metadata_startup_script = templatefile("${path.module}/scripts/startup-compute.sh", {
    filestore_ip = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
  })
  depends_on = [ google_compute_instance.login_node ]
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
    #access_config {} # Enables external IP
  }

  tags = ["gpu-node", "slurm-cluster"]

  metadata_startup_script = templatefile("${path.module}/scripts/startup-gpu.sh", {
    filestore_ip = google_filestore_instance.slurm_storage.networks[0].ip_addresses[0]
  })

  depends_on = [ google_compute_instance.login_node ]
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