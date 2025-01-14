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

cat <<EOT | sudo tee /home/slurmadmin/public-key
---- BEGIN SSH2 PUBLIC KEY ----
Comment: "rsa-key-20250113"
AAAAB3NzaC1yc2EAAAADAQABAAABAQCsdQFzBXSMqLP3KpwC0EvR4hhC1KDCDGO+
XuemH+TM3XWhL9gYgKZQu1ocgd7F7yiJik0TBPUJ/ahSS5Uw4ditZofJgU4Wsk/M
o2sa/WQp4aOSoOMwEqwD0EZlnBOD629lXwtPxfiGGdqt5du8ZaB66zJfgt6rNmSd
ObPS0TAN7GhPVHWPhJdfyhxx8hcjSop9krSXF8px5VCrC+x9Y6TzY5sx5XDLh0gw
AHclDfDTx430BK+ZFmJhWJ+XrCzCOBV0G5xNgSqw/Ju8X9Pju3UlF1M5YKVDFaRA
jZyC4FcHejcrUh6XnurJk3arHvI/WoEjET/r9Tjxw3bBbA5jT7Hd
---- END SSH2 PUBLIC KEY ----
EOT
