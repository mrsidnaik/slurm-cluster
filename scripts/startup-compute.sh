# startup-compute.sh
#!/bin/bash
# Startup script for compute node

# Install dependencies
dnf update -y
dnf install -y slurm
dnf install -y nfs-utils
dnf install -y munge munge-libs munge-devel

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge (key needs to be copied from login node)
mkdir -p /etc/munge
scp ${login_node_ip}:/etc/munge/munge.key /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl enable munge
systemctl start munge

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