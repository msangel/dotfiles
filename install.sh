#!/usr/bin/env bash

set -Eeuo pipefail

DOWNLOAD_PLAYBOOK=true
USE_LOCAL_ROLE=false
LOG_LEVEL=0

if [[ "$DOWNLOAD_PLAYBOOK" != true && "$DOWNLOAD_PLAYBOOK" != false ]]; then
    echo "DOWNLOAD_PLAYBOOK must be true or false" >&2
    exit 1
fi

if [[ "$USE_LOCAL_ROLE" != true && "$USE_LOCAL_ROLE" != false ]]; then
    echo "USE_LOCAL_ROLE must be true or false" >&2
    exit 1
fi

if [[ ! "$LOG_LEVEL" =~ ^[0-4]$ ]]; then
    echo "LOG_LEVEL must be an integer from 0 to 4" >&2
    exit 1
fi

RAW_REPO_URL="https://raw.githubusercontent.com/msangel/dotfiles/master"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$USE_LOCAL_ROLE" == true && ! -f "$SCRIPT_DIR/tasks/main.yml" ]]; then
    echo "USE_LOCAL_ROLE=true requires local role files next to install.sh" >&2
    exit 1
fi

if [[ "$DOWNLOAD_PLAYBOOK" == true ]]; then
    WORK_DIR="$(mktemp -d)"
    PLAYBOOK="$WORK_DIR/playbook.yml"

    trap 'rm -rf "$WORK_DIR"' EXIT

    echo "Downloading playbook.yml..."

    curl -fsSL \
        "$RAW_REPO_URL/playbook.yml" \
        -o "$PLAYBOOK"

    echo "File downloaded to [$PLAYBOOK]"
elif [[ "$DOWNLOAD_PLAYBOOK" == false ]]; then
    PLAYBOOK="$SCRIPT_DIR/playbook.yml"

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
    -i localhost,
    --connection=local
    -e "target_user=$TARGET_USER"
    -e "target_home=$TARGET_HOME"
    -e "ansible_python_interpreter=$(command -v python3)"
    -e "use_local_role=$USE_LOCAL_ROLE"
    -e "local_role_path=$SCRIPT_DIR"
)

ANSIBLE_ENV=()

if (( LOG_LEVEL == 0 )); then
    ANSIBLE_ENV+=(
        ANSIBLE_DISPLAY_OK_HOSTS=false
        ANSIBLE_DISPLAY_SKIPPED_HOSTS=false
    )
fi

if (( LOG_LEVEL > 0 )); then
    verbosity=""

    for ((i = 0; i < LOG_LEVEL; i++)); do
        verbosity+="v"
    done

    ANSIBLE_ARGS+=("-$verbosity")
fi

if [[ "$EUID" -ne 0 ]]; then
    ANSIBLE_ARGS+=(--ask-become-pass)
fi

env "${ANSIBLE_ENV[@]}" ansible-playbook \
    "${ANSIBLE_ARGS[@]}" \
    "$PLAYBOOK"
