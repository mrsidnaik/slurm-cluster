# startup-login.sh
#!/bin/bash
# Startup script for login node

# Install dependencies
sudo dnf update -y
sudo dnf config-manager --set-enabled powertools
sudo dnf install -y epel-release
sudo dnf install -y slurm slurm-slurmd
sudo dnf install -y nfs-utils
sudo dnf install -y munge munge-libs

# Mount shared storage
mkdir -p /shared
echo "${filestore_ip}:/nfs1 /shared nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure munge
mkdir -p /etc/munge
create-munge-key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key

sudo systemctl enable munge
sudo systemctl start munge

# Configure slurm
mkdir -p /etc/slurm /var/spool/slurmd
chown slurm:slurm /var/spool/slurmd
touch /var/log/slurmd.log /var/log/slurmctld.log
chown slurm:slurm /var/log/slurmd.log /var/log/slurmctld.log

cat <<EOT | sudo tee /etc/slurm/slurm.conf
ControlMachine=login-node
SlurmUser=slurm
StateSaveLocation=/var/spool/slurmd
SlurmdSpoolDir=/var/spool/slurmd
AuthType=auth/munge
SchedulerType=sched/backfill
NodeName=compute-node CPUs=8 RealMemory=32000
NodeName=gpu-node CPUs=12 RealMemory=48000 Gres=gpu:1
PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP
EOT

systemctl enable slurmctld
systemctl start slurmctld


# Create users
useradd -m -G wheel slurmadmin
useradd -m slurmuser
usermod -aG slurm slurmuser

