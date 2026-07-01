#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE="${ROOT_DIR}/.env.example"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Erro: comando obrigatorio nao encontrado: ${command_name}" >&2
    exit 1
  fi
}

create_env_file() {
  if [[ -f "${ENV_FILE}" ]]; then
    return
  fi

  cp "${ENV_EXAMPLE}" "${ENV_FILE}"
  sed -i "s/^PUID=.*/PUID=$(id -u)/" "${ENV_FILE}"
  sed -i "s/^PGID=.*/PGID=$(id -g)/" "${ENV_FILE}"
}

create_directories() {
  local directories=(
    "filebrowser/database"
    "homarr/configs"
    "homarr/icons"
    "jellyfin/cache"
    "jellyfin/config"
    "librespeed/config"
    "netdata/cache"
    "netdata/config"
    "netdata/lib"
    "n8n/data"
    "portainer/data"
    "prowlarr/config"
    "qbittorrent/config"
    "radarr/config"
    "swingmusic/config"
    "uptime-kuma/data"
  )

  local path
  for path in "${directories[@]}"; do
    mkdir -p "${ROOT_DIR}/${path}"
  done
}

main() {
  require_command docker
  docker compose version >/dev/null 2>&1 || {
    echo "Erro: docker compose nao esta disponivel neste host." >&2
    exit 1
  }

  cd "${ROOT_DIR}"
  create_env_file
  create_directories

  docker compose --env-file "${ENV_FILE}" config >/dev/null
  docker compose --env-file "${ENV_FILE}" up -d

  echo "Stack iniciado com sucesso."
}

main "$@"
