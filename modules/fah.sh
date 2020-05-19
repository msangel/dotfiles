#!/bin/bash

# debconf tutorial
# https://feeding.cloud.geek.nz/posts/manipulating-debconf-settings-on/

apt install python-gnome2 dh-python -q -y


if ! dpkg -l | grep -q fahclient; then
    rm fahclient_7.5.1_amd64.deb
    echo "start download fahclient_7.5.1_amd64.deb"
    wget https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.5/fahclient_7.5.1_amd64.deb
    USERID="modern_sky_angel"
    TEAM="47191"
    PASSKEY="7264df85e01393f42c2ac9a3e1f0666d"
    POWER="medium" # light|medium|full
    
    echo "FAHClient    fahclient/user       string $USERID"        | debconf-set-selections
    echo "FAHClient    fahclient/team       string $TEAM"          | debconf-set-selections
    echo "FAHClient    fahclient/passkey    string $PASSKEY"       | debconf-set-selections
    echo "FAHClient    fahclient/power      select $POWER"         | debconf-set-selections
    echo "FAHClient    fahclient/autostart  boolean true"          | debconf-set-selections

    # show values:
    #   sudo debconf-show FAHClient
    # remove values:
    #   https://serverfault.com/a/332490/146810
    #   echo PURGE | sudo debconf-communicate FAHClient
    
    dpkg -i fahclient_7.5.1_amd64.deb
    sleep 1
    update-rc.d FAHClient defaults
    sleep 1
    dpkg --configure -a
    rm fahclient_7.5.1_amd64.deb
fi

if ! dpkg -l | grep -q fahcontrol; then
    rm fahcontrol_7.5.1-1_all.deb
    echo "start download fahcontrol_7.5.1-1_all.deb"
    wget https://download.foldingathome.org/releases/public/release/fahcontrol/debian-stable-64bit/v7.5/fahcontrol_7.5.1-1_all.deb
    dpkg -i fahcontrol_7.5.1-1_all.deb
    rm fahcontrol_7.5.1-1_all.deb
fi


# sudo dpkg -P fahclient
# sudo dpkg -P fahcontrol
# sudo rm /etc/fahclient/config.xml
