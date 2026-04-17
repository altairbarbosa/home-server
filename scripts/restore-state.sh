#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /caminho/do/backup.tar.gz" >&2
  exit 1
fi

ARCHIVE_PATH="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  echo "Erro: arquivo de backup nao encontrado: ${ARCHIVE_PATH}" >&2
  exit 1
fi

cd "${ROOT_DIR}"
tar -xzf "${ARCHIVE_PATH}"

echo "Backup restaurado em: ${ROOT_DIR}"
