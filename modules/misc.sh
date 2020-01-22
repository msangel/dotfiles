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
            arc-theme \
            numix-icon-theme-circle \
            openconnect \
            network-manager-openconnect \
            network-manager-openconnect-gnome \
            build-essential -q -y


timedatectl set-timezone "Europe/Kiev"

if ! grep -q first_weekday /usr/share/i18n/locales/en_US; then
    printf "first_weekday 2\n" >> /usr/share/i18n/locales/en_US
    locale-gen
else
    if [[ "2" -ne `sed -rn "s|first_weekday (.)|\1|p" /usr/share/i18n/locales/en_US` ]]; then
        sed -ri "s|first_weekday (.)|first_weekday 2|" /usr/share/i18n/locales/en_US
        locale-gen
    fi
fi


