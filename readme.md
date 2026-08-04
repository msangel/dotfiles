# (\.file)*

## execute
```bash
cd; curl -LO https://raw.githubusercontent.com/msangel/dotfiles/master/install.sh && sudo bash install.sh
```


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

