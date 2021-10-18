#!/bin/bash
# https://serverfault.com/a/453325/146810
# ssh-keygen -l -f foo.txt

if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
  ssh-keygen -t rsa -b 4096 -C "h6.msangel@gmail.com" -f ~/.ssh/id_rsa -q -P ""
fi
# might consider turn off strict checking of ssh keys: https://serverfault.com/questions/506864/turn-off-strict-checking-of-ssh-keys

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
echo "Public key for this machine:"
cat ~/.ssh/id_rsa.pub
git config --global user.email "h6.msangel@gmail.com"
git config --global user.name "Vasyl Khrystiuk"

# git shell support
if [[ ! -d ~/.bash-git-prompt ]]; then
  git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1
fi


if ! grep -q bash-git-prompt ~/.bashrc; then
  echo "bash-git-prompt not installed, so adding one"
  cat <<<"
if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
   source $HOME/.bash-git-prompt/gitprompt.sh
   export GIT_PROMPT_THEME=Single_line_Dark
fi" >> ~/.bashrc
else
  echo "bash-git-prompt already installed, no need to add one"
fi
