#!/usr/bin/env bash

set -Eeuo pipefail

DOWNLOAD_PLAYBOOK=false

RAW_REPO_URL="https://raw.githubusercontent.com/msangel/dotfiles/master"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$DOWNLOAD_PLAYBOOK" == true ]]; then
    WORK_DIR="$(mktemp -d)"
    PLAYBOOK="$WORK_DIR/ansible.yaml"

    trap 'rm -rf "$WORK_DIR"' EXIT

    echo "Downloading ansible.yaml..."

    curl -fsSL \
        "$RAW_REPO_URL/ansible.yaml" \
        -o "$PLAYBOOK"

    echo "File downloaded to [$PLAYBOOK]"
elif [[ "$DOWNLOAD_PLAYBOOK" == false ]]; then
    PLAYBOOK="$SCRIPT_DIR/ansible.yaml"

    if [[ ! -f "$PLAYBOOK" ]]; then
        echo "Not found: $PLAYBOOK" >&2
        exit 1
    fi

    echo "Using local playbook [$PLAYBOOK]"
else
    echo "DOWNLOAD_PLAYBOOK must be true or false" >&2
    exit 1
fi

TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible..."

    APT_ENV=(
        DEBIAN_FRONTEND=noninteractive
        DEBCONF_NONINTERACTIVE_SEEN=true
        TZ=Europe/Kyiv
    )

    if [[ "$EUID" -eq 0 ]]; then
        env "${APT_ENV[@]}" apt-get update
        env "${APT_ENV[@]}" apt-get install -y ansible
    else
        sudo env "${APT_ENV[@]}" apt-get update
        sudo env "${APT_ENV[@]}" apt-get install -y ansible
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
