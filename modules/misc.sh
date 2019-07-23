#!/bin/bash
# sudo add-apt-repository ppa:gezakovacs/ppa
# sudo apt update
# sudo apt install unetbootin

apt purge --auto-remove hexchat pidgin mpv -q -y

# misc
apt install baobab \
            gparted \
            transmission \
            apt-transport-https \
            git \
            vim \
            kazam \
            autoconf \
            fonts-noto-color-emoji \
            neofetch \
            indicator-cpufreq \
            wget \
            curl \
            telnet \
            vlc \
            build-essential -q -y


timedatectl set-timezone "Europe/Kiev"
