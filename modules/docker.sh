#!/bin/bash
# docker
# instruction from here: https://docs.docker.com/install/linux/docker-ce/ubuntu/
# remove old if any
apt-get remove docker docker-engine docker.io containerd runc
# install deps:
apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common -q -y
if ! grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -e 'docker' | grep -v '#'; then
    echo "Docker repo is not found in the system, adding one"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    # if I will ever need to automate the repository deletion: grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/*
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update
else
  echo "Docker repo is in the system dont need to add anymore"
fi

apt install docker-ce docker-ce-cli containerd.io -q -y
groupadd docker
usermod -aG docker $USER
# fix if old rooted docker run was executed
chown "$USER":"$USER" /home/"$USER"/.docker -R
chmod g+rwx "$HOME/.docker" -R
# more precise config here: https://docs.docker.com/install/linux/linux-postinstall/
