#!/bin/bash


# resources:
# https://docs.xfce.org/xfce/xfconf/xfconf-query
# https://forum.xfce.org/viewtopic.php?id=8619
# https://github.com/jokandre/arch-post-install
# todo: https://wired-mind.info/post/528

. /etc/os-release

function is_xfce()
{
  [[ $XDG_CURRENT_DESKTOP = "XFCE" ]]
}

function is_gallium_os()
{
  [[ $NAME = "GalliumOS" ]]
}


if is_xfce; then
    # xfpanel-switch
    XFCE_PANEL_DIRECTORY="${HOME}"'/.config/xfce4/panel'
    echo 'NOTE: Clearing the XFCE panels.'
    xfconf-query --channel 'xfce4-panel' --property '/panels' --reset  --recursive
    xfconf-query --channel 'xfce4-panel' --property '/panels' --create --force-array --type int --set 0
    xfconf-query --channel 'xfce4-panel' --property '/plugins' --reset --recursive
    # rm --force --recursive --verbose "${XFCE_PANEL_DIRECTORY}"
    # mkdir --parents --verbose "${XFCE_PANEL_DIRECTORY}"


    xfconf-query -c xfce4-panel -p /panels -n -t int -s 0 -a
    # p=8: bottom left corner, the constant of enum _SnapPosition from from panel/panel-window.c xfce4-panel sources
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/position"         -t string -s "p=8;x=0;y=0"
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/position-locked"  -t bool   -s true
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/size"             -t int    -s 32
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/background-alpha" -t int    -s 80
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/disable-struts"   -t bool   -s false
    xfconf-query -n -c xfce4-panel -p "/panels/panel-0/length"           -t int    -s 100
    if is_gallium_os; then
        xfconf-query -n -c xfce4-panel -p "/panels/panel-0/plugin-ids" -a \
            -t int -s 1  -t int -s 2  -t int -s 3  -t int -s 4  -t int -s 5  \
            -t int -s 6  -t int -s 7  -t int -s 8  -t int -s 9  -t int -s 10 \
            -t int -s 11 -t int -s 12 -t int -s 13

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-1"  -t string -s whiskermenu
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-2"  -t string -s launcher
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-2/items" -t string -s '14449738812.desktop' -a

    mkdir -v ${XFCE_PANEL_DIRECTORY}/launcher-2/
    cat > ${XFCE_PANEL_DIRECTORY}/launcher-2/14449738812.desktop <<EOL
[Desktop Entry]
Name=Thunar File Manager
Comment=Browse the filesystem with the file manager
GenericName=File Manager
Exec=thunar %F
Icon=Thunar
Terminal=false
StartupNotify=true
Type=Application
Categories=System;Utility;Core;GTK;FileTools;FileManager;
X-XFCE-Source=file:///usr/share/applications/Thunar.desktop
EOL

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-3"  -t string -s launcher
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-3/items" -t string -s '14449738943.desktop' -a
    mkdir -v ${XFCE_PANEL_DIRECTORY}/launcher-3/
    cat > ${XFCE_PANEL_DIRECTORY}/launcher-3/14449738943.desktop <<EOL
[Desktop Entry]
Version=1.0
Name=Xfce Terminal
Comment=Terminal Emulator
GenericName=Terminal Emulator
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=GTK;System;TerminalEmulator;
StartupNotify=true
X-XFCE-Source=file:///usr/share/applications/xfce4-terminal.desktop
EOL

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-4"  -t string -s launcher
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-4/items" -t string -s '14449738521.desktop' -a
    mkdir -v ${XFCE_PANEL_DIRECTORY}/launcher-4/
    cat > ${XFCE_PANEL_DIRECTORY}/launcher-4/14449738521.desktop <<EOL
[Desktop Entry]
Version=1.0
Name=Chromium Web Browser
GenericName=Web Browser
Comment=Access the Internet
Exec=chromium-browser %U
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=chromium-browser
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Chromium-browser
StartupNotify=true
Actions=NewWindow;Incognito;TempProfile;
X-AppInstall-Package=chromium-browser
X-XFCE-Source=file:///usr/share/applications/chromium-browser.desktop

[Desktop Action NewWindow]
Name=Open a New Window
Exec=chromium-browser

[Desktop Action Incognito]
Name=Open a New Window in incognito mode
Exec=chromium-browser --incognito

[Desktop Action TempProfile]
Name=Open a New Window with a temporary profile
Exec=chromium-browser --temp-profile
EOL

    xfconf-query -n -c xfce4-panel -p /plugins/plugin-5  -t string -s launcher
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-5/items" -t string -s '15644454781.desktop' -a
    mkdir -v ${XFCE_PANEL_DIRECTORY}/launcher-5/
    cat > ${XFCE_PANEL_DIRECTORY}/launcher-5/15644454781.desktop <<EOL
[Desktop Entry]
X-SnapInstanceName=intellij-idea-ultimate
Version=1.0
Type=Application
Name=IntelliJ IDEA Ultimate Edition
Icon=/snap/intellij-idea-ultimate/current/bin/idea.svg
Exec=env BAMF_DESKTOP_FILE_HINT=/var/lib/snapd/desktop/applications/intellij-idea-ultimate_intellij-idea-ultimate.desktop /snap/bin/intellij-idea-ultimate %f
Comment=Capable and Ergonomic IDE for JVM
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea
X-XFCE-Source=file:///var/lib/snapd/desktop/applications/intellij-idea-ultimate_intellij-idea-ultimate.desktop
EOL

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-6"                   -t string   -s tasklist
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-6/flat-buttons"      -t bool     -s true
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-6/show-handle"       -t bool     -s true
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-6/window-scrolling"  -t bool     -s false


    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-7"                   -t string   -s separator
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-7/expand"            -t bool     -s true
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-7/style"             -t int      -s 0

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-8"                   -t string   -s separator
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-8/style"             -t int      -s 0

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-9"                   -t string   -s notification-plugin

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-10"                  -t string   -s systray
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-10/show-frame"       -t bool     -s false
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-10/size-max"         -t int      -s 26

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-10/names-visible" -a \
            -t string -s 'thunar'                   \
            -t string -s 'kazam'                    \
            -t string -s 'vpnui'                    \
            -t string -s 'networkmanager applet'    \
            -t string -s 'task manager'             \
            -t string -s 'indicator-cpufreq'        \
            -t string -s 'network'                  \
            -t string -s 'pasystray'                \
            -t string -s 'blueman-applet'           \
            -t string -s 'vncserverui'              \
            -t string -s 'zoom'                     \
            -t string -s 'skypeforlinux'            \
            -t string -s 'xfce4-power-manager'      \
            -t string -s 'slack'

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-11"                  -t string   -s 'power-manager-plugin'

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-12"                  -t string   -s 'clock'
    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-12/timezone"         -t string   -s 'Europe/Kiev'

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-13"                  -t string   -s 'xkb'

    xfconf-query -n -c xfce4-panel -p "/plugins/plugin-14"                  -t string   -s 'showdesktop'

    else
        echo "add work config here"
    fi
fi

# todo: rc files (loke here: https://github.com/jokandre/arch-post-install/tree/a07d756db345902fc9f0cff47bb7b6e9bb4a5a9a/xfce-panel)
# plan

# 0) set single workspace
xfconf-query -c xfwm4 -p /general/workspace_count -s 1
xfconf-query --channel 'xfce4-panel' --property '/panels/panel-1' --reset  --recursive


if grep -q button-icon ~/.config/xfce4/panel/whiskermenu-1.rc; then
    sed -ri "s|button-icon=.*\n|button-icon=/usr/share/pixmaps/xubuntu-logo-menu.png|" ~/.config/xfce4/panel/whiskermenu-1.rc
fi


# 2) change theme, appearance, icon theme
# change gtk theme:
xfconf-query -c xsettings -p /Net/ThemeName -s 'Arc-Dark-GalliumOS'

# change wm theme:
xfconf-query -c xfwm4 -p /general/theme -s 'Arc-Dark-GalliumOS'
# change icon theme
xfconf-query -c xsettings -p /Net/IconThemeName -s "Numix-Circle-GalliumOS"
# change background
# default is fine
# xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorHDMI-0/workspace0/last-image -s /path/to/your/image.jpg


# for work PC it should work as expected, for home notebook it should not
if is_gallium_os; then
  # disable screensaver via xfconf-query
  xfconf-query -c xfce4-session -np /shutdown/LockScreen -t 'bool' -s 'false'
  xfconf-query -c xfce4-power-manager -np /xfce4-power-manager/lock-screen-suspend-hibernate -t 'bool' -s 'false'
  # and remove it from aurostart
  if [ -f /etc/xdg/autostart/xscreensaver.desktop ]; then
    rm /etc/xdg/autostart/xscreensaver.desktop
  fi
  # too critical, lets avoid that, as an option ise better screenloker, like 
  #   ex +g/xscreensaver-command/d -cwq /usr/bin/xflock4
  # also: use better screenlocker: https://bluesabre.org/2019/08/06/xfce-screensaver-0-1-7-released/
  # xfconf-query -c xfce4-session -p /general/LockCommand -s "gnome-screensaver-command --lock" --create -t string
fi

# sudo apt-get install light-locker
# sudo dpkg-reconfigure lightdm
# >Default display manager: lightdm, lxdm - pick lxdm

# add timezones to clock: https://unix.stackexchange.com/questions/23218/how-to-add-a-custom-timezone-clock-to-an-xfce-panel
# shoild be done during building panel


# also stored here: $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
xfconf-query -c keyboard-layout -p /Default/XkbDisable -s false
# more here: man xkeyboard-config
xfconf-query -c keyboard-layout -p /Default/XkbOptions/Group -s "grp:lwin_toggle"
xfconf-query -c keyboard-layout -p /Default/XkbModel -s "chromebook_m_ralt"
xfconf-query -c keyboard-layout -pn /Default/XkbLayout -t 'string' -s "us,ua,ru"
xfconf-query -c keyboard-layout -pn /Default/XkbVariant -t 'string' -s ",,"

# another global hotkeys fix
xfconf-query -c xfce4-keyboard-shortcuts -pn "/commands/custom/<Primary><Shift>F5" -t string -s "xfce4-screenshooter -r"
xfconf-query -c xfce4-keyboard-shortcuts -pn "/commands/custom/<Primary><Shift>XF86Display" -t string -s "xfce4-screenshooter -r"




# Update xfce4-panel clock
# https://unix.stackexchange.com/a/227405/143394
# https://unix.stackexchange.com/a/451744
timezone="Europe/Kiev"
if property=$(xfconf-query -c xfce4-panel --list | grep timezone); then
  if [[ $(wc -l <<<"$property") -eq 1 ]]; then # only one clock widget
    xfconf-query -c xfce4-panel -p "$property" -s "$timezone"
    printf '\nUpdated xfce4-panel clock timezone to: %s\n' "$timezone"
  else
    printf >&2 'Not changing multiple xfce4-panel properties:\n%s\n' "$property"
  fi
fi

xfce4-panel --restart
