#!/bin/bash
# skype
if ! dpkg -l | grep -q skypeforlinux; then
    apt install libgdk-pixbuf-xlib-2.0-0 libgdk-pixbuf2.0-0 -y -q
    wget https://repo.skype.com/latest/skypeforlinux-64.deb
    dpkg -i skypeforlinux-64.deb
    rm skypeforlinux-64.deb
    # see also here as skype uses legacy keystore: https://askubuntu.com/questions/1403556/key-is-stored-in-legacy-trusted-gpg-keyring-after-ubuntu-22-04-update
fi
