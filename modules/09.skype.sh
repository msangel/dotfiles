#!/bin/bash
# skype
if ! dpkg -l | grep -q skypeforlinux; then
    wget https://repo.skype.com/latest/skypeforlinux-64.deb
    dpkg -i skypeforlinux-64.deb
    rm skypeforlinux-64.deb
fi
