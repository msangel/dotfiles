#!/bin/bash

# cisco anyconnect
if ! dpkg -l | grep -q libpangox-1.0-0; then
    apt install libpangox-1.0-0 -q -y
fi

if ! dpkg -l | grep -q wmctrl; then
    apt install wmctrl -q -y
fi

if [[  "`cat /opt/cisco/anyconnect/update.txt 2>/dev/null`" <  "4,2,04039" ]]; then
    echo "Cisco anyconnect not installed or less version"
    if [[ -f "bin/vpnsetup.sh" ]]; then
        vpnsetup="bin/vpnsetup.sh"
    elif [[ -f "./../bin/vpnsetup.sh" ]]; then
        vpnsetup=`realpath "./../bin/vpnsetup.sh"`
    fi
    chmod +x "$vpnsetup"
    eval $vpnsetup
    
    
    # https://askubuntu.com/questions/646346/xfce-hiding-an-application-from-the-taskbar
    if ! grep -q vpnui.vpnui ~/.bashrc; then
      echo "Hiding vpn client to tray client script was not found, so adding one(first)"
      echo "wmctrl -x -r vpnui.vpnui -b add,skip_taskbar" >> ~/.bashrc
    else
      echo "Hiding vpn client to tray script was found, no need to add one"
    fi

    if ! grep -q "Cisco AnyConnect Secure Mobility Client" ~/.bashrc; then
      cat <<<'
wmctrl -x -r "Cisco AnyConnect Secure Mobility Client"."Cisco AnyConnect Secure Mobility Client" -b add,skip_taskbar
' >> ~/.bashrc
    else
      echo "Hiding vpn client to tray script was found, no need to add one"
    fi

    if [[ -e ~/.local/share/applications/menulibre-cisco-anyconnect.desktop ]]; then
      echo "found file: ~/.local/share/applications/menulibre-cisco-anyconnect.desktop "
      if ! grep -q Categories= ~/.local/share/applications/menulibre-cisco-anyconnect.desktop; then
        echo "but categories in it not found"
        echo "Categories=Network;Security;" >> ~/.local/share/applications/menulibre-cisco-anyconnect.desktop
      else
        echo "and categories fine there: $(grep Categories= ~/.local/share/applications/menulibre-cisco-anyconnect.desktop)"
      fi
      rm -f /usr/share/applications/cisco-anyconnect.desktop
    elif [[ -e /usr/share/applications/cisco-anyconnect.desktop ]]; then
      echo "found file: /usr/share/applications/cisco-anyconnect.desktop"
      if ! grep -q Categories= /usr/share/applications/cisco-anyconnect.desktop; then
        echo "but categories in it not found"
        echo "Categories=Network;Security;" >> /usr/share/applications/cisco-anyconnect.desktop
      else
        echo "and categories fine there: $(grep Categories= /usr/share/applications/cisco-anyconnect.desktop)"
      fi
    fi
else
  echo "Cisco anyconnect installed and is this or more high version"
fi



# Uninstalling the client
# sudo /opt/cisco/vpn/bin/vpn_uninstall.sh
# or
# sudo /opt/cisco/anyconnect/bin/anyconnect_uninstall.sh
# However it doesn't actually uninstall everything properly, it removes files but leaves
# behind directories. You can clean up what it leaves behind by deleting the
# directory /opt/cisco/
# sudo rm -r /opt/cisco
# Per-user configuration is stored in your home directory in a file called .anyconnect
