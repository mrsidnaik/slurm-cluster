# startup-compute.sh
#!/bin/bash
# Startup script for compute node

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

#
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD5O/hyTWSEaIfLI2OuSZMRRe6MX4LWGW1WyGD05n8s8GA3z3/YSJkf6ORcNffy9QmGt76SjiQtWsQW/7WV5Et4MrZ1gID+8cCP0IAdGPq8wj2AXUQipo+ULcpNdQ953aXEBWo+JBwRq5yYEJL65tWMKhmT7ZIk0HfTJPZidc4qaiEKGwQRFsRQrbIIcgguVp8epvRjDrVtfPMulff//xi4TwX9bEYba3ssaLlgOtr0GtMbOCVzHsIdYCtaB0mV/RH7obkK0NIcXIBseMskRt31yRDSLQJZH8NIpP+4taa9XhtlyLdAE6OBk/9rSTz9kvo7JwYpDwqK5FOiHpghG132bTSOqriD3yh1/MW6tSSGyYxK/mWNm6sianmL1r0vovh/xllglOs164a97uEiFpupt9v9Oe71RlGY09Pw3f7Fzd1D4Ay1MZujagooMKqiiQPAc0/JUisY3/jx7MHY7zzW7eu+oRkPD+aPQYBugNtXz4O5o5tKw9WdVgiGbxuPlAOS6qN5daoToOAfsP6EjbkuSzONPhnbbWRl79jWVEiJ2c1XZyPh2Rvu8NAcAUOp/wEjR4tjAbfq8UACD4e5vxLZBOOgMESnKZCQL7AIWE5lShzhllmqQHND3lmHKiVzh7d90hv2eM9mHznTfOx340Jlk1Nm55/8AKWC5JAxTbIosw==" >> ~/.ssh/authorized_keys
sudo systemctl restart sshd
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config