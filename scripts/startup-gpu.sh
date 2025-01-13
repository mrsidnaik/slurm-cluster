# startup-gpu.sh
#!/bin/bash
# Startup script for GPU node

# Install dependencies
dnf update -y
dnf install -y epel-release
dnf install -y wget curl gcc make nfs-utils
dnf install -y slurm slurm-devel munge munge-libs

# Install NVIDIA drivers
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
dnf install -y cuda-drivers

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/vol1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge (key needs to be copied from login node)
systemctl enable munge
systemctl start munge

# Configure GPU for Slurm
cat > /etc/slurm/gres.conf <<EOL
NodeName=gpu-1 Name=gpu File=/dev/nvidia0
EOL

# Start Slurm daemon
systemctl enable slurmd
systemctl start slurmd

# Create users (should match login node)
useradd -m -G wheel slurmadmin
useradd -m username
usermod -aG slurm username

# Start NVIDIA services
systemctl enable nvidia-persistenced
systemctl start nvidia-persistenced