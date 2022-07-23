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
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    # if I will ever need to automate the repository deletion: grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/*
    echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
else
  echo "Docker repo is in the system dont need to add anymore"
fi

apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -q -y

# more precise config here: https://docs.docker.com/install/linux/linux-postinstall/
sudo groupadd docker
sudo usermod -aG docker $USER
# relogin required!

