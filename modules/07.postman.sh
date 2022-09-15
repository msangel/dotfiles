#!/bin/bash

if ! dpkg -l | grep -q snapd; then
    apt install snapd -q -y
fi

if ! grep -q "/snap/bin" /etc/environment; then
    sed -ri "s|PATH=\"(.*)(\")|PATH=\"\1:/snap/bin\"|" /etc/environment
fi

snap install postman
snap install pinta
 
