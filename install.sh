#!/usr/bin/env bash
set -euo pipefail

umask 077
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/flop-agent"

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }
python3 -c 'import cryptography' >/dev/null 2>&1 || {
  echo "Python package cryptography is required. Install python3-cryptography first." >&2
  exit 1
}

install -d -m 700 "${TARGET_DIR}"
install -m 700 "${SCRIPT_DIR}/agent.py" "${TARGET_DIR}/agent.py"
install -m 700 "${SCRIPT_DIR}/show-did.py" "${TARGET_DIR}/show-did.py"
install -m 700 "${SCRIPT_DIR}/registry-retry.py" "${TARGET_DIR}/registry-retry.py"
install -m 600 "${SCRIPT_DIR}/flop-agent.service" "${TARGET_DIR}/flop-agent.service"
install -m 600 "${SCRIPT_DIR}/flop-agent.timer" "${TARGET_DIR}/flop-agent.timer"
install -m 600 "${SCRIPT_DIR}/flop-agent-registry.service" "${TARGET_DIR}/flop-agent-registry.service"
install -m 600 "${SCRIPT_DIR}/flop-agent-registry.timer" "${TARGET_DIR}/flop-agent-registry.timer"

read -r -p "Encrypted identity backup path (leave empty for a new DID): " BACKUP_FILE
if [[ -n "${BACKUP_FILE}" ]]; then
  [[ -f "${BACKUP_FILE}" ]] || { echo "Backup file not found: ${BACKUP_FILE}" >&2; exit 1; }
  temporary_identity="$(mktemp "${TARGET_DIR}/.identity.XXXXXX")"
  cleanup() { rm -f -- "${temporary_identity}"; }
  trap cleanup EXIT
  read -r -s -p "Backup password: " BACKUP_PASSWORD
  printf '\n'
  export BACKUP_PASSWORD
  openssl enc -d -aes-256-cbc -md sha256 -pbkdf2 -iter 300000 \
    -in "${BACKUP_FILE}" -out "${temporary_identity}" \
    -pass env:BACKUP_PASSWORD
  unset BACKUP_PASSWORD
  chmod 600 "${temporary_identity}"
  mv -- "${temporary_identity}" "${TARGET_DIR}/flop_agent_identity.json"
  trap - EXIT
fi

install -d -m 700 "${HOME}/.config/systemd/user"
install -m 600 "${TARGET_DIR}/flop-agent.service" "${HOME}/.config/systemd/user/flop-agent.service"
install -m 600 "${TARGET_DIR}/flop-agent.timer" "${HOME}/.config/systemd/user/flop-agent.timer"
install -m 600 "${TARGET_DIR}/flop-agent-registry.service" "${HOME}/.config/systemd/user/flop-agent-registry.service"
install -m 600 "${TARGET_DIR}/flop-agent-registry.timer" "${HOME}/.config/systemd/user/flop-agent-registry.timer"

systemctl --user daemon-reload
systemctl --user enable --now flop-agent.timer flop-agent-registry.timer

echo "Installed in ${TARGET_DIR}."
echo "The weekly check-in timer and two-hour registry retry are active."
echo "If this is a migration, stop the old server's timers before starting this identity here."
echo "To keep timers alive after logout: sudo loginctl enable-linger \"${USER}\""
