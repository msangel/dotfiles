# comment
---
- name: Configure fresh OS
  hosts: localhost
  connection: local
  become: true

  vars:
    is_container: >-
      {{
        ansible_facts.virtualization_type | default('')
        in ['docker', 'containerd', 'podman']
      }}

    target_user: >-
      {{
        lookup('env', 'TARGET_USER')
        | default(lookup('env', 'SUDO_USER'), true)
        | default(lookup('env', 'USER'), true)
      }}
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
   
    numix_folder_style: "1"
    numix_folder_colour: blue #green

    xfce_gtk_theme: Arc-Dark
    xfce_icon_theme: Numix-Circle
    xfce_window_theme: Arc-Dark
    
    xfce_settings:
        - channel: xsettings
          property: /Net/ThemeName
          value: "{{ xfce_gtk_theme }}"
          type: string

        - channel: xsettings
          property: /Net/IconThemeName
          value: "{{ xfce_icon_theme }}"
          type: string

        - channel: xfwm4
          property: /general/theme
          value: "{{ xfce_window_theme }}"
          type: string

        - channel: xfwm4
          property: /general/mousewheel_rollup
          value: "false"
          type: bool

        - channel: thunar
          property: /last-show-hidden
          value: "true"
          type: bool

        - channel: xfwm4
          property: /general/workspace_count
          value: "1"
          type: int


  pre_tasks:
    - name: Resolve target user home
      ansible.builtin.getent:
        database: passwd
        key: "{{ target_user }}"
      when: target_home is not defined

    - name: Set target user home
      ansible.builtin.set_fact:
        target_home: "{{ ansible_facts.getent_passwd[target_user][4] }}"
      when: target_home is not defined

    - name: Resolve target user primary group
      ansible.builtin.command:
        argv:
          - id
          - -gn
          - "{{ target_user }}"
      register: target_group_result
      changed_when: false
      when: target_group is not defined

    - name: Set target user primary group
      ansible.builtin.set_fact:
        target_group: "{{ target_group_result.stdout }}"
      when: target_group is not defined

  tasks:
    - name: Disable .xsession-errors
      ansible.builtin.file:
        src: /dev/null
        dest: "{{ target_home }}/.xsession-errors"
        state: link
        force: true
        owner: "{{ target_user }}"
        group: "{{ target_group }}"

    - name: Remove conflicting Docker packages
      apt:
        name:
          - docker.io
          - docker-compose
          - docker-compose-v2
          - docker-doc
          - podman-docker
          - hexchat
          - pidgin
          - engrampa
          - mpv
          - ayatana-indicator-application
        state: absent

    - name: Install required packages
      apt:
        name:
          - wget
          - gnupg
          - ca-certificates
          - curl
          - util-linux-extra
          - baobab
          - peek
          - gparted
          - transmission
          - apt-transport-https
          - git
          - vim
          - kazam
          - xrestop
          - autoconf
          - fonts-noto-color-emoji
          - fastfetch
          - indicator-cpufreq
          - thunar-gtkhash
          - net-tools
          - conntrack
          - telnet
          - vlc
          - arc-theme
          - openconnect
          - network-manager-openconnect
          - network-manager-openconnect-gnome
          - xarchiver
          - playerctl
          - seahorse
          - mugshot
          - build-essential
          - atril
          - libnotify-dev
          - numix-icon-theme
          - numix-icon-theme-circle
          - jq
          - tar
          - unzip
          - zip
          - xfconf                    # default in Xubuntu
          - dbus-x11                  # default in Xubuntu
          - dconf-cli
          - xdg-desktop-portal
          - xdg-desktop-portal-gtk
        state: present
        cache_valid_time: 3600

    - name: Check if Google Chrome is installed
      command: dpkg-query -W -f='${Status}' google-chrome-stable
      register: chrome_check
      failed_when: false
      changed_when: false

    - name: Create keyrings directory
      file:
        path: /etc/apt/keyrings
        state: directory
        mode: '0755'

    - name: Download Google Chrome GPG key
      get_url:
        url: https://dl.google.com/linux/linux_signing_key.pub
        dest: /etc/apt/keyrings/google-chrome.asc
        mode: '0644'
      when: chrome_check.rc != 0

    - name: Add Google Chrome repository
      apt_repository:
        repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] http://dl.google.com/linux/chrome/deb/ stable main"
        state: present
        filename: google-chrome
      register: chrome_repo_result

    - name: Install Google Chrome
      apt:
        name: google-chrome-stable
        state: present
        update_cache: "{{ chrome_repo_result.changed }}"

    - name: Install Postman
      community.general.snap:
        name: postman
        state: present
      when: not is_container

    - name: Install SDKMAN
      ansible.builtin.shell: |
        set -o pipefail
        curl --fail --silent --show-error --location https://get.sdkman.io | bash
      args:
        executable: /bin/bash
        creates: "{{ target_home }}/.sdkman/bin/sdkman-init.sh"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"

    - name: Get target user UID
      ansible.builtin.command:
        argv:
          - id
          - -u
          - "{{ target_user }}"
      register: target_uid_result
      changed_when: false

    - name: Check active user session bus
      ansible.builtin.stat:
        path: "/run/user/{{ target_uid_result.stdout }}/bus"
      register: xfce_session_bus

    - name: Stop Thunar before changing its settings
      ansible.builtin.command:
        argv:
          - thunar
          - --quit
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      failed_when: false
      changed_when: false
      when: xfce_session_bus.stat.exists

    - name: Download Numix Folders
      git:
        repo: https://github.com/numixproject/numix-folders.git
        dest: /opt/numix-folders
        version: master
        force: true

    - name: Add Numix Folders command
      file:
        src: /opt/numix-folders/numix-folders
        dest: /usr/local/bin/numix-folders
        state: link

    - name: Create user config directory
      ansible.builtin.file:
        path: "{{ target_home }}/.config"
        state: directory
        owner: "{{ target_user }}"
        group: "{{ target_group }}"
        mode: "0755"

    - name: Configure Numix folder style
      copy:
        dest: "{{ target_home }}/.config/numix-folders"
        owner: "{{ target_user }}"
        group: "{{ target_group }}"
        mode: "0644"
        content: |
          {{ numix_folder_style }}
          {{ numix_folder_colour }}
          000000
          000000
          000000
      register: numix_folders_config_result


    - name: Apply Numix folder style
      command:
        argv:
          - /usr/local/bin/numix-folders
          - --prev
      environment:
        SUDO_USER: "{{ target_user }}"
        HOME: "{{ target_home }}"
      when: >-
        numix_folders_config_result.changed

    - name: Read current Xfce theme settings
      ansible.builtin.command:
        argv:
          - xfconf-query
          - --channel
          - "{{ item.channel }}"
          - --property
          - "{{ item.property }}"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      register: xfce_theme_current
      changed_when: false
      failed_when: false
      when: xfce_session_bus.stat.exists
      loop: "{{ xfce_settings }}"
      loop_control:
        label: "{{ item.property }}"

    - name: Apply Xfce settings to active session
      ansible.builtin.command:
        argv:
          - xfconf-query
          - --channel
          - "{{ item.item.channel }}"
          - --property
          - "{{ item.item.property }}"
          - --create
          - --type
          - "{{ item.item.type | default('string') }}"
          - --set
          - "{{ item.item.value }}"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      when:
        - xfce_session_bus.stat.exists
        - item.rc != 0 or (item.stdout | trim) != item.item.value
      loop: "{{ xfce_theme_current.results }}"
      loop_control:
        label: "{{ item.item.property }} = {{ item.item.value }}"

    - name: Configure Xfce themes for next login
      ansible.builtin.command:
        argv:
          - dbus-run-session
          - --
          - xfconf-query
          - --channel
          - "{{ item.channel }}"
          - --property
          - "{{ item.property }}"
          - --create
          - --type
          - "{{ item.type | default('string') }}"
          - --set
          - "{{ item.value }}"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
      when: not xfce_session_bus.stat.exists
      loop: "{{ xfce_settings }}"
      loop_control:
        label: "{{ item.property }} = {{ item.value }}"


# we need to sent event to apps abouth theme chanhe, best is to loop thought current -> default -> selected 
    - name: Force Xfce GTK theme refresh
      ansible.builtin.command:
        argv:
          - xfconf-query
          - --channel
          - xsettings
          - --property
          - /Net/ThemeName
          - --set
          - "{{ item }}"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      loop:
        - Default
        - "{{ xfce_gtk_theme }}"
      when: xfce_session_bus.stat.exists
      changed_when: true

# alternative 
#    - name: Set preferred dark system color scheme
#      community.general.dconf:
#        key: /org/gnome/desktop/interface/color-scheme
#        value: "'prefer-dark'"
#        state: present
#      become_user: "{{ target_user }}"
#      environment:
#        HOME: "{{ target_home }}"

    - name: Refresh Numix icon caches
      ansible.builtin.command:
        argv:
          - gtk-update-icon-cache
          - --force
          - "{{ item }}"
      loop:
        - /usr/share/icons/Numix
        - /usr/share/icons/Numix-Circle
      changed_when: true


    - name: Get latest JetBrains Toolbox release
      ansible.builtin.uri:
        url: https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release
        return_content: true
      register: jetbrains_toolbox_release
      changed_when: false


    - name: Install JetBrains Toolbox
      ansible.builtin.shell: |
        set -euo pipefail

        install_dir="{{ target_home }}/.local/opt/jetbrains-toolbox"
        tmp_dir="$(mktemp -d)"

        trap 'rm -rf "$tmp_dir"' EXIT

        curl \
          --fail \
          --location \
          --show-error \
          --output "$tmp_dir/jetbrains-toolbox.tar.gz" \
          "{{ jetbrains_toolbox_release.json.TBA[0].downloads.linux.link }}"

        rm -rf "$install_dir"
        mkdir -p "$install_dir"

        tar \
          --extract \
          --gzip \
          --file "$tmp_dir/jetbrains-toolbox.tar.gz" \
          --directory "$install_dir" \
          --strip-components=1
      args:
        executable: /bin/bash
        creates: "{{ target_home }}/.local/opt/jetbrains-toolbox/bin/jetbrains-toolbox"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"


    - name: Create user autostart directory
      ansible.builtin.file:
        path: "{{ target_home }}/.config/autostart"
        state: directory
        owner: "{{ target_user }}"
        group: "{{ target_group }}"
        mode: "0755"

    - name: Add JetBrains Toolbox to autostart
      ansible.builtin.copy:
        dest: "{{ target_home }}/.config/autostart/jetbrains-toolbox.desktop"
        owner: "{{ target_user }}"
        group: "{{ target_group }}"
        mode: "0644"
        content: |
          [Desktop Entry]
          Type=Application
          Name=JetBrains Toolbox
          Exec={{ target_home }}/.local/opt/jetbrains-toolbox/bin/jetbrains-toolbox
          Icon=jetbrains-toolbox
          Terminal=false
          X-GNOME-Autostart-enabled=true

    - name: Get latest IntelliJ IDEA Ultimate release
      ansible.builtin.uri:
        url: https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release
        return_content: true
      register: intellij_idea_release
      changed_when: false

    - name: Install IntelliJ IDEA Ultimate
      ansible.builtin.shell: |
        set -euo pipefail

        install_dir="{{ target_home }}/.local/share/JetBrains/Toolbox/apps/intellij-idea"
        tmp_dir="$(mktemp -d)"

        trap 'rm -rf "$tmp_dir"' EXIT

        curl \
          --fail \
          --location \
          --show-error \
          --output "$tmp_dir/intellij-idea.tar.gz" \
          "{{ intellij_idea_release.json.IIU[0].downloads.linux.link }}"

        rm -rf "$install_dir"
        mkdir -p "$install_dir"

        tar \
          --extract \
          --gzip \
          --file "$tmp_dir/intellij-idea.tar.gz" \
          --directory "$install_dir" \
          --strip-components=1
      args:
        executable: /bin/bash
        creates: "{{ target_home }}/.local/share/JetBrains/Toolbox/apps/intellij-idea/bin/idea"
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"

    - name: Download Docker GPG key
      ansible.builtin.get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker.asc
        mode: "0644"
      register: docker_gpg_key_result

    - name: Add Docker apt repository
      ansible.builtin.copy:
        dest: /etc/apt/sources.list.d/docker.sources
        mode: "0644"
        content: |
          Types: deb
          URIs: https://download.docker.com/linux/ubuntu
          Suites: {{ ansible_facts.distribution_release }}
          Components: stable
          Architectures: amd64
          Signed-By: /etc/apt/keyrings/docker.asc
      register: docker_repo_result

    - name: Install Docker packages
      ansible.builtin.apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
          - docker-ce-rootless-extras
          - uidmap
          - dbus-user-session
          - slirp4netns
          - fuse-overlayfs
        state: present
        update_cache: >-
          {{
            docker_gpg_key_result.changed
            or docker_repo_result.changed
          }}

    - name: Enable and start rootful Docker
      ansible.builtin.systemd_service:
        name: docker
        enabled: true
        state: started
      when: not is_container

    - name: Add target user to docker group
      ansible.builtin.user:
        name: "{{ target_user }}"
        groups: docker
        append: true

    - name: Enable lingering for target user
      ansible.builtin.command:
        argv:
          - loginctl
          - enable-linger
          - "{{ target_user }}"
      args:
        creates: "/var/lib/systemd/linger/{{ target_user }}"
      when: not is_container

    - name: Install Docker rootless service for target user
      ansible.builtin.shell: |
        set -euo pipefail

        if systemctl --user is-enabled docker.service >/dev/null 2>&1; then
          systemctl --user start docker.service
          exit 0
        fi

        dockerd-rootless-setuptool.sh install --force

        systemctl --user enable docker.service
        systemctl --user start docker.service

        echo changed
      args:
        executable: /bin/bash
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      register: docker_rootless_result
      changed_when: "'changed' in docker_rootless_result.stdout"
      when: not is_container

    - name: Create rootless Docker systemd override directory
      ansible.builtin.file:
        path: "{{ target_home }}/.config/systemd/user/docker.service.d"
        state: directory
        mode: "0755"
      become_user: "{{ target_user }}"
      when: not is_container

    - name: Configure rootless Docker host loopback access
      ansible.builtin.copy:
        dest: "{{ target_home }}/.config/systemd/user/docker.service.d/override.conf"
        mode: "0644"
        content: |
          [Service]
          Environment="DOCKERD_ROOTLESS_ROOTLESSKIT_DISABLE_HOST_LOOPBACK=false"
      become_user: "{{ target_user }}"
      register: docker_rootless_override_result
      when: not is_container

    - name: Create rootless Docker config directory
      ansible.builtin.file:
        path: "{{ target_home }}/.config/docker"
        state: directory
        mode: "0755"
      become_user: "{{ target_user }}"
      when: not is_container

    - name: Configure rootless Docker daemon
      ansible.builtin.copy:
        dest: "{{ target_home }}/.config/docker/daemon.json"
        mode: "0644"
        content: |
          {
            "host-gateway-ip": "10.0.2.2"
          }
      become_user: "{{ target_user }}"
      register: docker_rootless_daemon_result
      when: not is_container

    - name: Reload and restart rootless Docker after config change
      ansible.builtin.shell: |
        set -euo pipefail

        systemctl --user daemon-reload
        systemctl --user restart docker.service
      args:
        executable: /bin/bash
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
        XDG_RUNTIME_DIR: "/run/user/{{ target_uid_result.stdout }}"
        DBUS_SESSION_BUS_ADDRESS: >-
          unix:path=/run/user/{{ target_uid_result.stdout }}/bus
      when:
        - not is_container
        - >-
          docker_rootless_override_result.changed
          or docker_rootless_daemon_result.changed
      changed_when: true

    - name: Install SDKMAN Java versions
      ansible.builtin.shell: |
        set -eo pipefail

        export SDKMAN_DIR="{{ target_home }}/.sdkman"
        source "$SDKMAN_DIR/bin/sdkman-init.sh"

        changed=0

        find_latest_java() {
          major="$1"
          vendor="$2"

          sdk list java |
            awk -F'|' '{
              gsub(/^[ \t]+|[ \t]+$/, "", $NF)
              print $NF
            }' |
            grep -E "^${major}\..*-${vendor}$" |
            head -n 1
        }

        is_major_installed() {
          major="$1"

          find "$SDKMAN_DIR/candidates/java" \
            -maxdepth 1 \
            -mindepth 1 \
            -type d \
            -name "${major}.*" \
            2>/dev/null |
          grep -q .
        }

        for major in 8 11 17 21 25; do
          if is_major_installed "$major"; then
            continue
          fi

          java_version="$(
            find_latest_java "$major" open || true
          )"

          if [ -z "$java_version" ]; then
            java_version="$(
              find_latest_java "$major" tem || true
            )"
          fi

          if [ -z "$java_version" ]; then
            echo \
              "No SDKMAN Java version found for major=$major" \
              >&2
            exit 1
          fi

          printf 'n\n' |
            sdk install java "$java_version"

          changed=1
        done

        if [ "$changed" = "1" ]; then
          echo changed
        fi
      args:
        executable: /bin/bash
      become_user: "{{ target_user }}"
      environment:
        HOME: "{{ target_home }}"
      register: sdkman_java_install_result
      changed_when: "'changed' in sdkman_java_install_result.stdout"

    - name: Autoremove unused apt packages
      ansible.builtin.apt:
        autoremove: true
        purge: true
