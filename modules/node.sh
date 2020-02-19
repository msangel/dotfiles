#!/bin/bash
apt install npm -q -y
npm install -g n
/usr/local/bin/n latest
if ! grep -q "NPM_PACKAGES" ~/.bashrc; then
    curl -LO https://raw.githubusercontent.com/glenpike/npm-g_nosudo/master/npm-g-nosudo.sh && printf "\ny\n" | sh npm-g-nosudo.sh
fi
# remove HARD
# http://manpages.ubuntu.com/manpages/bionic/man1/removing-npm.1.html
