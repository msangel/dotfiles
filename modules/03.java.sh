#!/bin/bash

# java version manager: https://github.com/shyiko/jabba (better then jenv)
export JABBA_VERSION=0.11.2
curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
jabba install adopt@1.8.0-292

# java 8?
# openjdk wich not require licensing
# add-apt-repository -y ppa:openjdk-r/ppa
# apt update
# apt install openjdk-8-jdk -q -y


# maven
apt install maven -q -y

# gradle helper
git clone https://github.com/dougborg/gdub.git
cd gdub
./install
cd ..
rm -rf gdub



