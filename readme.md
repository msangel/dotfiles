# (\.file)*

## execute

`cd; curl -LO https://raw.githubusercontent.com/msangel/dotfiles/master/install.sh && sudo bash install.sh`


## testing env from github
```bash
docker run --rm -it \
  --hostname xubuntu-test \
  ubuntu:26.04 \
  bash -lc '
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true
    export TZ=Europe/Kyiv

    apt-get update -qq
    apt-get install -yqq sudo curl ca-certificates </dev/null

    useradd -m -s /bin/bash -G sudo msangel
    echo "msangel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/msangel
    chmod 440 /etc/sudoers.d/msangel

    exec setpriv \
      --reuid=msangel \
      --regid=msangel \
      --init-groups \
      env HOME=/home/msangel USER=msangel LOGNAME=msangel \
      bash -lc "
        cd
        curl -fsSLO https://raw.githubusercontent.com/msangel/dotfiles/master/install.sh
        sudo bash install.sh
        exec bash -l
      "
  '
```

## testing env from local
```bash
docker run --rm -it \
  --hostname xubuntu-test \
  --mount type=bind,src="$(pwd)",dst=/workspace,readonly \
  ubuntu:26.04 \
  bash -lc '
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true
    export TZ=Europe/Kyiv

    apt-get update -qq
    apt-get install -yqq sudo curl ca-certificates </dev/null

    useradd -m -s /bin/bash -G sudo msangel
    echo "msangel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/msangel
    chmod 440 /etc/sudoers.d/msangel

    exec setpriv \
      --reuid=msangel \
      --regid=msangel \
      --init-groups \
      env HOME=/home/msangel USER=msangel LOGNAME=msangel \
      bash -lc "
        cd /workspace
        bash ./install.sh
        exec bash -l
      "
  '
```

# hardware
* https://laptopmedia.com/laptop-specs/acer-swift-3-sf315-52-10/
  * linux mic problem:
    * main discussion: https://bugzilla.kernel.org/show_bug.cgi?id=201251
    * on alsa page: https://bugs.launchpad.net/ubuntu/+source/alsa-driver/+bug/1793410
    * retasker: https://www.omgubuntu.co.uk/2013/12/turn-headphone-jack-microphone-jack-ubuntu
    * ru forum: https://4pda.ru/forum/index.php?showtopic=910434
    * working solution: https://kdi.net.ua/mini-usb-mikrofon-dlya-noutbuka/
* type C charger: 19.5V 2.25A
* mouse manhattan 177474
* gamepad https://askubuntu.com/questions/32031/how-do-i-configure-a-joystick-or-gamepad

service: http://team.ua/team-service-centre/warranty/brands/

# wallpaper
https://www.pling.com/p/1337517/
https://chrome.google.com/webstore/detail/james-white/bkeidgmehkdjmpjodpjkepolokanalkm

# face auth
https://github.com/boltgolt/howdy

# power management 
http://tdkare.ru/sysadmin/index.php/Preload
http://tdkare.ru/sysadmin/index.php/Prelink

# gestures
https://gist.github.com/darcyparker/3d89e7851fc10992000e

dm:
cat /etc/X11/default-display-manager
/usr/sbin/lightdm

antlr
cisco
etcher
jd-gui
mindustry
openconnect
TeradataStudioExpress
tomcat
visualvm
