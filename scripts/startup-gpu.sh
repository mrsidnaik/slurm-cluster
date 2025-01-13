# startup-gpu.sh
#!/bin/bash
# Startup script for GPU node

# Install dependencies
sudo dnf update -y
sudo dnf config-manager --set-enabled powertools
sudo dnf install -y epel-release
sudo dnf install -y slurm slurm-slurmd
sudo dnf install -y nfs-utils
sudo dnf install -y munge munge-libs

# Install NVIDIA drivers
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
dnf install -y cuda-drivers

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/vol1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge (key needs to be copied from login node)
mkdir -p /etc/munge
scp ${login_node_ip}:/etc/munge/munge.key /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl enable munge
systemctl start munge

# Configure GPU for Slurm
cat > /etc/slurm/gres.conf <<EOL
NodeName=gpu-node Name=gpu File=/dev/nvidia0
EOL

# Start Slurm daemon
mkdir -p /etc/slurm /var/spool/slurmd
chown slurm:slurm /var/spool/slurmd
scp ${login_node_ip}:/etc/slurm/slurm.conf /etc/slurm/slurm.conf
systemctl enable slurmd
systemctl start slurmd

# Create users (should match login node)
useradd -m -G wheel slurmadmin
useradd -m slurmuser
usermod -aG slurm slurmuser

# Start NVIDIA services
systemctl enable nvidia-persistenced
systemctl start nvidia-persistenced