# TARGET_USER="${SUDO_USER:-$USER}"
# sudo -u "$TARGET_USER" dbus-run-session -- xfconf-query -c xfce4-terminal -p /scrolling-unlimited -n -t bool -s true
  
if command -v xfconf-query >/dev/null 2>&1; then
  xfconf-query -c xfce4-terminal -p /scrolling-unlimited -n -t bool -s true
fi
