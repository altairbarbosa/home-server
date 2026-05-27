#!/usr/bin/env bash
set -euo pipefail

SERVER_SHARE_NAME="${SERVER_SHARE_NAME:-e-cube}"
SERVER_SHARE_PATH="${SERVER_SHARE_PATH:-/}"
SAMBA_USER="${SAMBA_USER:-altair}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

if [[ ! -d "${SHARE_PATH}" ]]; then
  echo "Share path does not exist: ${SHARE_PATH}" >&2
  exit 1
fi

echo "==> Installing Samba"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y samba samba-common-bin avahi-daemon curl ca-certificates

SMB_CONF="/etc/samba/smb.conf"
BACKUP="${SMB_CONF}.backup.$(date +%Y%m%d-%H%M%S)"
cp "${SMB_CONF}" "${BACKUP}"
echo "==> Backed up Samba config to ${BACKUP}"

echo "==> Configuring Samba shares"
python3 - "${SMB_CONF}" "${SAMBA_USER}" \
  "${SERVER_SHARE_NAME}" "${SERVER_SHARE_PATH}" <<'PY'
from pathlib import Path
import re
import sys

conf_path = Path(sys.argv[1])
samba_user = sys.argv[2]
shares = [(sys.argv[i], sys.argv[i + 1]) for i in range(3, len(sys.argv), 2)]

text = conf_path.read_text()
for old_share in ("HomeServer", "HDs", "Servidor", "printers", "print$"):
    text = re.sub(rf"(?ms)^\[{re.escape(old_share)}\]\n.*?(?=^\[|\Z)", "", text)

for share_name, share_path in shares:
    if share_path == "/":
        masks = """
   create mask = 0777
   directory mask = 0777"""
        extra = f"""
   writable = yes
   write list = {samba_user}
   admin users = {samba_user}
   force create mode = 0666
   force directory mode = 0777
   delete readonly = yes
   dos filemode = yes
   ea support = yes
   vfs objects = catia fruit streams_xattr
   fruit:aapl = yes
   fruit:metadata = stream
   fruit:resource = stream
   fruit:encoding = native
   fruit:locking = none
   nt acl support = no
   map archive = no
   map hidden = no
   map system = no
   store dos attributes = no"""
    elif share_path == "/mnt":
        masks = """
   create mask = 0777
   directory mask = 0777"""
        extra = f"""
   force user = {samba_user}
   force group = {samba_user}
   force create mode = 0666
   force directory mode = 0777
   delete readonly = yes"""
    else:
        masks = """
   create mask = 0664
   directory mask = 0775"""
        extra = """
   force group = docker"""

    block = f"""

[{share_name}]
   path = {share_path}
   browseable = yes
   read only = no
   valid users = {samba_user}{masks}{extra}
"""

    pattern = re.compile(rf"(?ms)^\[{re.escape(share_name)}\]\n.*?(?=^\[|\Z)")
    if pattern.search(text):
        text = pattern.sub(block.lstrip(), text)
    else:
        text = text.rstrip() + block

conf_path.write_text(text)
PY

if getent group docker >/dev/null && id "${SAMBA_USER}" >/dev/null 2>&1; then
  usermod -aG docker "${SAMBA_USER}"
fi

testparm -s "${SMB_CONF}" >/dev/null
systemctl enable --now smbd nmbd avahi-daemon
systemctl restart smbd nmbd

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  echo "==> Allowing Samba through UFW"
  ufw allow Samba
fi

if ! pdbedit -L | cut -d: -f1 | grep -qx "${SAMBA_USER}"; then
  echo
  echo "==> Samba user password required"
  echo "Create the SMB password for ${SAMBA_USER}. This can be the same as your Linux password, but it is stored separately by Samba."
  if [[ -n "${SMB_PASSWORD:-}" ]]; then
    printf '%s\n%s\n' "${SMB_PASSWORD}" "${SMB_PASSWORD}" | smbpasswd -s -a "${SAMBA_USER}"
  else
    smbpasswd -a "${SAMBA_USER}"
  fi
else
  echo "==> Samba user ${SAMBA_USER} already exists"
fi

echo "==> Installing Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

systemctl enable --now tailscaled

echo
echo "==> Starting Tailscale login"
echo "Open the login URL printed below and sign in with your Tailscale account."
tailscale up --ssh

echo
echo "==> Done"
echo "LAN SMB address: smb://$(hostname -I | awk '{print $1}')/${SHARE_NAME}"
if tailscale ip -4 >/dev/null 2>&1; then
  echo "Tailscale SMB address: smb://$(tailscale ip -4 | head -n1)/${SHARE_NAME}"
fi
