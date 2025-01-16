# startup-gpu.sh
#!/bin/bash
# Startup script for GPU node

sudo su

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


# Install NVIDIA drivers
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf install -y cuda-toolkit
sudo dnf install nvidia-gds

# Mount shared storage
sudo mkdir -p /shared
sudo echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
sudo mount -a

# Configure munge (key needs to be copied from login node)
sudo mkdir -p /etc/munge
sudo cp /shared/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl start munge

# Configure GPU for Slurm
sudo cat > /etc/slurm/gres.conf <<EOL
NodeName=gpu-node Name=gpu File=/dev/nvidia0
EOL

# Start Slurm daemon
sudo mkdir -p /etc/slurm /var/spool/slurmd
sudo chown slurm:slurm /var/spool/slurmd
sudo cp /shared/slurm.conf /etc/slurm/slurm.conf
sudo systemctl enable slurmd
sudo systemctl start slurmd