#!/bin/bash
# sudo add-apt-repository ppa:gezakovacs/ppa
# sudo apt update
# sudo apt install unetbootin

apt purge --auto-remove hexchat \
            pidgin \
            thunderbird \
            xfce4-screensaver \
            xscreensaver \
            engrampa \
            mpv -q -y

# misc
apt install baobab \
            mousepad \
            gparted \
            transmission \
            apt-transport-https \
            git \
            vim \
            kazam \
            xrestop \
            autoconf \
            fonts-noto-color-emoji \
            neofetch \
            indicator-cpufreq \
            kdocker \
            thunar-gtkhash \
            net-tools \
            wget \
            curl \
            telnet \
            vlc \
            arc-theme \
            numix-icon-theme-circle \
            openconnect \
            network-manager-openconnect \
            network-manager-openconnect-gnome \
            xarchiver \
            tlp tlp-rdw \
            seahorse \
            mugshot \
            gnupg \
            ca-certificates \
            artil \
            build-essential -q -y


# used by numix-folders utility
apt install libnotify-dev  -q -y
# https://github.com/numixproject/numix-folders

# snap packages here
if ! dpkg -l | grep -q snapd; then
    apt install snapd -q -y
fi

if ! grep -q "/snap/bin" /etc/environment; then
    sed -ri "s|PATH=\"(.*)(\")|PATH=\"\1:/snap/bin\"|" /etc/environment
fi

snap install postman
snap install pinta
 



# https://forum.xfce.org/viewtopic.php?id=10743
# https://askubuntu.com/a/333604/267916
# echo KERNEL=="nvme0n1p3", ENV{UDISKS_IGNORE}="1" > /etc/udev/rules.d/99-hide-partition.rules
# sudo udevadm trigger

# get the settings of scroll and gestures:
# synclient
# set values there sample (this one increase two finger scroll speed)
# synclient VertScrollDelta=15 HorizScrollDelta=15


# disable not-used USB device
# list devices:
# > for device in $(ls /sys/bus/usb/devices/*/product); do echo $device;cat $device;done
# https://stackoverflow.com/a/4702316/449553
# root@nb7:/sys/bus/usb/devices/1-9/power# echo disabled > wakeup
# reboot
# echo suspend > /sys/bus/usb/devices/1-9/power/level

# freeze linux kernel version
# known good version is: 5.3.0-40.32
# use "ukuu" for view and manage
# https://askubuntu.com/questions/678630/how-can-i-avoid-kernel-updates
# sudo apt install linux-image-5.3.0-40 linux-modules-extra-5.3.0-40 linux-modules-5.3.0-40 linux-headers-5.3.0-40 
# sudo apt-mark hold linux-image-generic linux-headers-generic linux-image linux-modules-extra linux-modules linux-headers
# apt-show-versions  libasound2 libasound2-data
# libasound2:amd64/eoan-updates 1.1.9-0ubuntu1.2 upgradeable to 1.1.9-0ubuntu1.3
# libasound2:i386 not installed
# libasound2-data:all/eoan-updates 1.1.9-0ubuntu1.2 upgradeable to 1.1.9-0ubuntu1.3
# sudo apt-mark hold libasound2 libasound2-data
