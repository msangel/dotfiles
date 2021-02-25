#!/bin/bash
# java 8?
# openjdk wich not require licensing
# add-apt-repository -y ppa:openjdk-r/ppa
# apt update
# apt install openjdk-8-jdk -q -y

# oracle jdk require login and accept license on oracle site:
# https://www.oracle.com/technetwork/java/javase/downloads/index.html
# after get jdk-*-linux-x64.tar.gz do this:
# java_archive=`realpath ~/Downloads/jdk-*-linux-x64.tar.gz`
# cd; curl -LO https://raw.githubusercontent.com/chrishantha/install-java/63997dc81aaf9184ffe715d7381fa822bd39f357/install-java.sh
# chmod +x install-java.sh
# sudo ./install-java.sh -f $java_archive
# split --bytes=45MB bin/jdk-8u221-linux-x64.tar.gz bin/jdk-8u221-linux-x64.part-
# mv bin/jdk-8u221-linux-x64.tar.gz bin/jdk-8u221-linux-x64.tar.gz.bak


if [[ ! -x "$(command -v javac)" ]] || [[ "`javac -version  2>&1 | awk '{print $2}'`" < "1.8.0_221" ]]; then
  echo "java is not installed OR the version is less then 1.8.0_221"
  cat bin/jdk-8u221-linux-x64.part-* > bin/jdk-8u221-linux-x64.tar.gz
  # sha1sum bin/jdk-8u221-linux-x64.tar.gz # 7752101e9aea1c416cd255f327e9346d9736fbb4
  if [[ "`sha1sum bin/jdk-8u221-linux-x64.tar.gz | awk '{print $1}'`" = "7752101e9aea1c416cd255f327e9346d9736fbb4" ]]; then
      chmod +x bin/install-java.sh
      bin/install-java.sh -f bin/jdk-8u221-linux-x64.tar.gz
  else
    echo "Java installer invalid checksum" >&2
  fi
else
  echo "java is installed and version is ok"
fi

# maven
apt install maven -q -y

# gradle helper
git clone https://github.com/dougborg/gdub.git
cd gdub
./install

# java version manager: https://github.com/jenv/jenv
