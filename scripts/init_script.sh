#!/bin/bash

USERNAME="lion"
PASSWORD="1212"
REMOTE_DIRECTORY="/home/$USERNAME/"

echo "Add user"
useradd -s /bin/bash -d $REMOTE_DIRECTORY -m $USERNAME

echo "Set password"
echo "$USERNAME:$PASSWORD" | chpasswd

echo "Set sudo"
usermod -aG sudo $USERNAME
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME

echo "Update apt and Install docker & docker-compose"
sudo apt-get update
sudo apt install -y docker.io docker-compose

echo "Start docker"
sudo service docker start && sudo service docker enable

echo "Add user to 'docker' group"
sudo usermod -aG docker $USERNAME

echo "done"
