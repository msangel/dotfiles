```bash
docker build \
  -t xubuntu-test-base \
  -f - \
  . <<'EOF'
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV TZ=Europe/Kyiv

RUN apt-get update && \
    apt-get install -y \
        ansible \
        sudo \
        jq \
        wget \
        gnupg \
        ca-certificates \
        curl \
        util-linux-extra \
        baobab \
        peek \
        gparted \
        transmission \
        apt-transport-https \
        git \
        vim \
        kazam \
        xrestop \
        autoconf \
        fonts-noto-color-emoji \
        fastfetch \
        indicator-cpufreq \
        thunar-gtkhash \
        net-tools \
        conntrack \
        telnet \
        vlc \
        arc-theme \
        numix-icon-theme-circle \
        openconnect \
        network-manager-openconnect \
        network-manager-openconnect-gnome \
        xarchiver \
        playerctl \
        seahorse \
        mugshot \
        build-essential \
        atril \
        libnotify-dev \
        dbus-x11 \
        desktop-file-utils \
        tar \
        xfconf && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -G sudo msangel && \
    echo "msangel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/msangel && \
    chmod 440 /etc/sudoers.d/msangel

USER msangel

ENV HOME=/home/msangel
ENV USER=msangel
ENV LOGNAME=msangel

WORKDIR /workspace

CMD ["bash"]
EOF
```

```
docker run --rm -it \
    --hostname xubuntu-test \
    --mount type=bind,src="$(pwd)",dst=/workspace,readonly \
    xubuntu-test-base \
    bash -lc '
        bash ./install.sh
        exec bash -l
    '
```
