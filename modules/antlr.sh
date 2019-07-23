#!/usr/bin/env bash

antlr_file="antlr-4.7.2-complete.jar"
if [[ -f /usr/local/lib/${antlr_file} ]]; then
    rm -v /usr/local/lib/${antlr_file}
fi
curl -o /usr/local/lib/${antlr_file} https://www.antlr.org/download/${antlr_file}

if ! grep -q "alias antlr4" ~/.bashrc; then
  printf "\n" >> ~/.bashrc
  echo "alias antlr4='java -jar /usr/local/lib/${antlr_file}'" >> ~/.bashrc
  echo "alias grun='java -classpath /usr/local/lib/${antlr_file} org.antlr.v4.gui.TestRig'" >> ~/.bashrc
fi

