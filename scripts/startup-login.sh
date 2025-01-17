# startup-login.sh
#!/bin/bash
# Startup script for login node

sudo su

# Install dependencies
sudo dnf update -y
sudo dnf config-manager --set-enabled powertools
sudo dnf install -y epel-release
sudo dnf install -y slurm slurm-slurmctld
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

# Configure munge
sudo mkdir -p /etc/munge
sudo create-munge-key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

sudo systemctl enable munge
sudo systemctl start munge

# Configure slurm
sudo mkdir -p /etc/slurm /var/spool/slurmd
sudo chown slurm:slurm /var/spool/slurmd
sudo touch /var/log/slurmd.log /var/log/slurmctld.log
sudo chown slurm:slurm /var/log/slurmd.log /var/log/slurmctld.log

sudo cat <<EOT | sudo tee /etc/slurm/slurm.conf
ClusterName=slurm-cluster
ControlMachine=login-node

SlurmUser=slurm
StateSaveLocation=/var/spool/slurmd
SlurmdSpoolDir=/var/spool/slurmd

AuthType=auth/munge
SchedulerType=sched/backfill

NodeName=compute-node CPUs=8 RealMemory=31000
NodeName=gpu-node CPUs=12 RealMemory=47000 Gres=gpu:1

PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP

SlurmdLogFile=/var/log/slurmd.log
SlurmctldLogFile=/var/log/slurmctld.log
EOT

#copy the slurm.conf and munge.key to the shared folder
sudo cp /etc/slurm/slurm.conf /shared/slurm.conf
sudo cp /etc/munge/munge.key /shared/munge.key

# Start slurm
sudo systemctl enable slurmctld
sudo systemctl start slurmctld
sudo scontrol reconfigure