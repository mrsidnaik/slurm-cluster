# startup-login.sh
#!/bin/bash
# Startup script for login node

# Install dependencies
dnf update -y
dnf install -y epel-release
dnf install -y wget curl gcc make nfs-utils
dnf install -y slurm slurm-devel munge munge-libs

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge
/usr/sbin/create-munge-key
systemctl enable munge
systemctl start munge

# Configure slurm
cat > /etc/slurm/slurm.conf <<EOL
ClusterName=gcp_cluster
ControlMachine=login-node
SlurmUser=slurm

NodeName=compute_node NodeAddr=COMPUTE_INTERNAL_IP CPUs=8 RealMemory=32000 State=UNKNOWN
NodeName=gpu_node NodeAddr=GPU_INTERNAL_IP CPUs=12 RealMemory=48000 Gres=gpu:l4:1 State=UNKNOWN

PartitionName=general Nodes=compute_node Default=YES MaxTime=INFINITE State=UP
PartitionName=gpu Nodes=gpu_node Default=NO MaxTime=INFINITE State=UP

SlurmctldPort=6817
SlurmdPort=6818
EOL

# Start Slurm controller
systemctl enable slurmctld
systemctl start slurmctld

# Create users
useradd -m -G wheel slurmadmin
useradd -m username
usermod -aG slurm username
