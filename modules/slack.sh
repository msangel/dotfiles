#!/bin/bash

if ! dpkg -l | grep -q snapd; then
    apt install snapd -q -y
fi

sudo apt install indicator-applet -y -q

if ! grep -q "/snap/bin" /etc/environment; then
    sed -ri "s|PATH=\"(.*)(\")|PATH=\"\1:/snap/bin\"|" /etc/environment
fi

snap install slack --classic
