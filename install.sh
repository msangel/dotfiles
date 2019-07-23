#!/bin/bash

###
# run this: cd; curl -LO https://raw.githubusercontent.com/msangel/dotfiles/master/install.sh && sudo bash install.sh
###

# Roadmap:
# use only as post-install script on fresh OS, so far, all modules will be installed in usual install mode
# but repeated run must not install already installed (ls -l modules | awk '{ print $9 }')
# [first run, repeative run] script
# __________________________________
# [+,+] docker.sh
# [+,+] fah.sh
# [+,+] git.sh
# [+,+] idea.sh
# [+,+] java.sh
# [+,+] misc.sh
# [+,+] node.sh
# [+,+] pinta.sh
# [+,+] postman.sh
# [+,+] python.sh
# [+,+] realvnc.sh
# [~,+]ruby.sh    <-- require relogin for continue
# [+,+] selenium.sh
# [+,+] skype.sh
# [+,+] slack.sh
# [-,-] wine.sh <-- you dont need this
# [+,+] xfce4-panels.sh
# [+,+] zoom.sh



if ! command -v git >/dev/null 2>&1 ; then
    apt install git
fi

basename_of_target_git="$(basename `git rev-parse --show-toplevel 2>/dev/null` 2>/dev/null)"

if [[ "$basename_of_target_git" = "dotfiles" ]]; then
  echo "inside git repo"
  cd `git rev-parse --show-toplevel`
else (
  echo "not in git repo, so clone that and pass control"
  if [[ -d "dotfiles" ]]; then
    rm -rf dotfiles
  fi
  su -c "git clone https://github.com/msangel/dotfiles" $SUDO_USER
  cd dotfiles
  sleep 4
  ./install.sh
  exit 0
  )
fi


function is_xfce()
{
  if [[ $XDG_CURRENT_DESKTOP = "XFCE" ]];
    then
    return 0
    fi
    return 1
}

apt update

# use includes:
# https://stackoverflow.com/a/41280223/449553
. $(dirname "$0")/modules/docker.sh
. $(dirname "$0")/modules/fah.sh
. $(dirname "$0")/modules/git.sh
. $(dirname "$0")/modules/idea.sh
. $(dirname "$0")/modules/java.sh
. $(dirname "$0")/modules/antlr.sh
. $(dirname "$0")/modules/misc.sh
. $(dirname "$0")/modules/node.sh
. $(dirname "$0")/modules/pinta.sh
. $(dirname "$0")/modules/postman.sh
. $(dirname "$0")/modules/python.sh
# . $(dirname "$0")/modules/realvnc.sh
# [~,+]ruby.sh    <-- require relogin for continue
. $(dirname "$0")/modules/selenium.sh
. $(dirname "$0")/modules/skype.sh
. $(dirname "$0")/modules/slack.sh
# [-,-] wine.sh <-- you dont need this
# su -c ". $(dirname "$0")/modules/xfce4-panels.sh" $SUDO_USER <-- require time to thing on each command and cannot run as root yet
. $(dirname "$0")/modules/zoom.sh


# save room
sudo apt-get autoremove
rm -r ${HOME}/.xsession-errors
ln -s /dev/null ${HOME}/.xsession-errors
