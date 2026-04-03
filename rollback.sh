#!/usr/bin/env bash
set -euo pipefail

CONF_FILE="/etc/sysctl.d/99-bbrplus.conf"
TARGET_CC="${1:-bbr}"

color() {
  local c="$1"; shift
  case "$c" in
    red) printf '\033[31m%s\033[0m\n' "$*" ;;
    green) printf '\033[32m%s\033[0m\n' "$*" ;;
    yellow) printf '\033[33m%s\033[0m\n' "$*" ;;
    blue) printf '\033[36m%s\033[0m\n' "$*" ;;
    *) echo "$*" ;;
  esac
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    color red "[错误] 请使用 root 运行此脚本"
    exit 1
  fi
}

require_root

if [[ "${TARGET_CC}" != "bbr" && "${TARGET_CC}" != "cubic" ]]; then
  color red "[错误] 仅支持回滚到: bbr 或 cubic"
  echo "用法: bash rollback.sh [bbr|cubic]"
  exit 1
fi

cat >"${CONF_FILE}" <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=${TARGET_CC}
EOF

sysctl --system >/dev/null

color green "[完成] 已切换到 ${TARGET_CC}"
sysctl net.ipv4.tcp_congestion_control || true
