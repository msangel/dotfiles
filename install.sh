#!/usr/bin/env bash

set -Eeuo pipefail

RAW_REPO_URL="https://raw.githubusercontent.com/msangel/dotfiles/master"

WORK_DIR="$(mktemp -d)"
PLAYBOOK="$WORK_DIR/ansible.yaml"

trap 'rm -rf "$WORK_DIR"' EXIT

TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "Downloading ansible.yaml..."
curl -fsSL \
    "$RAW_REPO_URL/ansible.yaml" \
    -o "$PLAYBOOK"

echo "File downloaded to [${PLAYBOOK}]..."

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible..."

    if [[ "$EUID" -eq 0 ]]; then
        env \
        DEBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        TZ=Europe/Kyiv \
        apt-get update
        env \
        DEBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        TZ=Europe/Kyiv \
        apt-get install -y ansible
    else
        env  \
        EBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        TZ=Europe/Kyiv \
        sudo apt-get update
        env \
        DEBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        TZ=Europe/Kyiv \
        sudo apt-get install -y ansible
    fi
fi

hash -r

ANSIBLE_ARGS=(
    -vvv
    -i localhost,
    --connection=local
    -e "target_user=$TARGET_USER"
    -e "target_home=$TARGET_HOME"
    -e "ansible_python_interpreter=$(command -v python3)"
)

if [[ "$EUID" -ne 0 ]]; then
    ANSIBLE_ARGS+=(--ask-become-pass)
fi

ansible-playbook \
    "${ANSIBLE_ARGS[@]}" \
    "$PLAYBOOK"
