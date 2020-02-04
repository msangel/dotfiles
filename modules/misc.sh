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
            light-locker \
            xarchiver \
            build-essential -q -y


timedatectl set-timezone "Europe/Kiev"

# better processor utilazing(keep cold and silent fan)
sudo add-apt-repository ppa:linrunner/tlp
sudo apt update
sudo apt install tlp tlp-rdw


if ! grep -q first_weekday /usr/share/i18n/locales/en_US; then
    printf "first_weekday 2\n" >> /usr/share/i18n/locales/en_US
    locale-gen
else
    if [[ "2" -ne `sed -rn "s|first_weekday (.)|\1|p" /usr/share/i18n/locales/en_US` ]]; then
        sed -ri "s|first_weekday (.)|first_weekday 2|" /usr/share/i18n/locales/en_US
        locale-gen
    fi
fi

# git clone https://github.com/GalliumOS/numix-icons-galliumos
# <rename>
# cd numix-icons-galliumos
# sudo apt install debhelper
# https://askubuntu.com/a/28373/267916
# dpkg-buildpackage -rfakeroot -uc -b
# cd ..
# sudo dpkg -i numix-icons-galliumos_3.0_all.deb 
# numix-icons-galliumos depends on xubuntu-icon-theme; however:
#  Package xubuntu-icon-theme is not installed.
# numix-icons-galliumos depends on numix-folders; however:
#  Package numix-folders is not installed.
# https://github.com/GalliumOS/numix-folders-galliumos


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
