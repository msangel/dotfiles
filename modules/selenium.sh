#!/bin/bash
echo selemium install start

if ! grep -q SELENIUM_CHROME_DRIVER ~/.bashrc; then
  chown -R $SUDO_USER:$(id -gn $SUDO_USER) $HOME/.npm
  chown -R $SUDO_USER:$(id -gn $SUDO_USER) $HOME/.npm-packages/
  su -c "npm uninstall -g chromedriver" $SUDO_USER 
  su -c "npm install -g chromedriver" $SUDO_USER
  printf "\\nexport SELENIUM_CHROME_DRIVER=\"`realpath ~`/.npm-packages/bin/chromedriver\"" >> ~/.bashrc
fi
