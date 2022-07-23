#!/bin/bash
# skype
if ! dpkg -l | grep -q skypeforlinux; then
    apt install libgdk-pixbuf-xlib-2.0-0 libgdk-pixbuf2.0-0 -y -q
    wget https://repo.skype.com/latest/skypeforlinux-64.deb
    dpkg -i skypeforlinux-64.deb
    rm skypeforlinux-64.deb
fi
