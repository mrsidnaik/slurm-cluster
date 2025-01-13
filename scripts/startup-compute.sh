# startup-compute.sh
#!/bin/bash
# Startup script for compute node

# Install dependencies
dnf update -y
dnf install -y epel-release
dnf install -y wget curl gcc make nfs-utils
dnf install -y slurm slurm-devel munge munge-libs

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge (key needs to be copied from login node)
systemctl enable munge
systemctl start munge

# Start Slurm daemon
systemctl enable slurmd
systemctl start slurmd

# Create users (should match login node)
useradd -m -G wheel slurmadmin
useradd -m slurmuser
usermod -aG slurm slurmuser