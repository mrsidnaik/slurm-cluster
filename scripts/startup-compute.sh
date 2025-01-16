# startup-compute.sh
#!/bin/bash
# Startup script for compute node

sudi su

# Install dependencies
sudo dnf update -y
sudo dnf config-manager --set-enabled powertools
sudo dnf install -y epel-release
sudo dnf install -y slurm slurm-slurmd
sudo dnf install -y nfs-utils
sudo dnf install -y munge munge-libs

# Create users
sudo useradd -m -G wheel slurmadmin
sudo groupadd slurm
sudo useradd -m slurmuser
sudo useradd -g slurm slurm
sudo usermod -aG slurm slurmuser

# Mount shared storage
sudo mkdir -p /shared
sudo echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
sudo systemctl daemon-reload
sudo mount -a

# Configure munge (key needs to be copied from login node)
sudo mkdir -p /etc/munge
sudo cp /shared/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl start munge

# Start Slurm daemon
sudo mkdir -p /etc/slurm /var/spool/slurmd
sudo chown slurm:slurm /var/spool/slurmd
sudo cp /shared/slurm.conf /etc/slurm/slurm.conf
sudo systemctl enable slurmd
sudo systemctl start slurmd
sudo scontrol reconfigure