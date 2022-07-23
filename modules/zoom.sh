#!/bin/bash

 apt install libxcb-xtest0 ibus dconf-cli gir1.2-ibus-1.0 libibus-1.0-5 libgl1-mesa-glx libegl1-mesa -y -q

if ! dpkg -l | grep -q zoom; then
    wget https://zoom.us/client/latest/zoom_amd64.deb
    dpkg -i zoom_amd64.deb
    rm zoom_amd64.deb
fi


