#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:altairbarbosa/home-server.git}"
TARGET_DIR="${TARGET_DIR:-/opt/media-stack}"
TARGET_OWNER="${TARGET_OWNER:-${SUDO_USER:-$USER}}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Execute este script com sudo." >&2
    exit 1
  fi
}

install_base_packages() {
  apt-get update
  apt-get install -y ca-certificates curl git
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release
  local docker_repo_distro="${ID}"

  case "${ID}" in
    ubuntu|debian)
      docker_repo_distro="${ID}"
      ;;
    *)
      echo "Distribuicao nao suportada por este script: ${ID}" >&2
      exit 1
      ;;
  esac

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${docker_repo_distro} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

ensure_target_dir() {
  install -d -m 0755 "$(dirname "${TARGET_DIR}")"

  if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    git clone "${REPO_URL}" "${TARGET_DIR}"
  else
    git -C "${TARGET_DIR}" pull --ff-only
  fi

  chown -R "${TARGET_OWNER}:${TARGET_OWNER}" "${TARGET_DIR}"
}

run_bootstrap() {
  sudo -u "${TARGET_OWNER}" "${TARGET_DIR}/scripts/bootstrap.sh"
}

main() {
  require_root
  install_base_packages
  install_docker
  ensure_target_dir
  run_bootstrap
}

main "$@"
