#!/bin/bash

sudo apt-get install gnupg2 -q -y

# install RVM
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
sudo usermod -a -G rvm $USER

# for ubuntu 22.04 the openssl3 is default. so for rubies must be compatible version, 
# at this moment it`s installing openssl1.0 into user-defined folder (default to $HOME/.rvm/usr)
rvm pkg install openssl
rvm install ruby-3.0.0 --with-openssl-dir=$HOME/.rvm/usr

# do this after restart/relogin
# As of writing this ruby-2.6.4 is the most recent version, we will use this and set it to our default version.
# rvm install 2.6.4
# https://stackoverflow.com/a/27415518/449553
# rvm use 2.5.1 --default
# ruby -v

# most common package
# gem install bundler
