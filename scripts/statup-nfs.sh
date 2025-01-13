#!/bin/bash
# NFS Server Setup

echo "Updating system packages..."
dnf update -y

echo "Installing NFS utilities..."
dnf install -y nfs-utils

echo "Creating shared directory..."
mkdir -p /shared
chown nobody:nogroup /shared
chmod 777 /shared

echo "Configuring NFS exports..."
echo "/shared 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

echo "Starting NFS server..."
systemctl enable nfs-server
systemctl start nfs-server

echo "NFS server setup complete."
