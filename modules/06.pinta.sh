#!/bin/bash

# pinta bug fix https://askubuntu.com/a/955564/267916
# https://www.mono-project.com/download/stable/#download-lin

if ! dpkg -l | grep -q pinta; then
  sudo apt install gnupg ca-certificates  -q -y
  sudo add-apt-repository -y ppa:pinta-maintainers/pinta-stable
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  echo "deb https://download.mono-project.com/repo/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

  sudo apt-get update

  sudo apt-get install pinta -q -y
  sudo apt install mono-devel -q -y
fi

