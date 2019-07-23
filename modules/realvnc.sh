#!/bin/bash
#real vnc:
if ! dpkg -l | grep -q realvnc-vnc-server; then
    wget https://www.realvnc.com/download/file/vnc.files/VNC-Server-6.5.0-Linux-x64.deb
    dpkg -i VNC-Server-6.5.0-Linux-x64.deb
    rm VNC-Server-6.5.0-Linux-x64.deb
fi

if ! dpkg -l | grep -q realvnc-vnc-viewer; then
    wget https://www.realvnc.com/download/file/viewer.files/VNC-Viewer-6.19.715-Linux-x64.deb
    dpkg -i VNC-Viewer-6.19.715-Linux-x64.deb
    rm VNC-Viewer-6.19.715-Linux-x64.deb
fi

systemctl enable vncserver-x11-serviced.service
systemctl start vncserver-x11-serviced.service

