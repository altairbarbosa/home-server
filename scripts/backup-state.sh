#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${1:-${ROOT_DIR}/backups}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="${BACKUP_DIR}/home-server-state-${TIMESTAMP}.tar.gz"

items=(
  "filebrowser/database"
  "homarr/configs"
  "homarr/icons"
  "jellyfin/config"
  "librespeed/config"
  "netdata/config"
  "netdata/lib"
  "portainer/data"
  "prowlarr/config"
  "qbittorrent/config"
  "radarr/config"
  "uptime-kuma/data"
)

mkdir -p "${BACKUP_DIR}"

cd "${ROOT_DIR}"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  items+=(".env")
fi

tar \
  --exclude='*.db-shm' \
  --exclude='*.db-wal' \
  --exclude='*.pid' \
  -czf "${ARCHIVE_PATH}" \
  "${items[@]}"

echo "Backup criado em: ${ARCHIVE_PATH}"
