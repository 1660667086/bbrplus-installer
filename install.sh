#!/usr/bin/env bash
set -euo pipefail

CONF_FILE="/etc/sysctl.d/99-bbrplus.conf"

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

supports_bbrplus() {
  local available_cc
  available_cc="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
  echo " ${available_cc} " | grep -qi ' bbrplus '
}

apply_bbrplus() {
  cat >"${CONF_FILE}" <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbrplus
EOF

  sysctl --system >/dev/null

  color green "[完成] 已写入 ${CONF_FILE}"
  color green "[完成] 已尝试启用 bbrplus"
  echo
  sysctl net.core.default_qdisc || true
  sysctl net.ipv4.tcp_congestion_control || true
}

require_root

color blue "[信息] 检测当前内核是否支持 bbrplus..."
if supports_bbrplus; then
  color green "[OK] 当前内核已支持 bbrplus，开始启用。"
  apply_bbrplus
else
  color yellow "[提示] 当前内核不支持 bbrplus。"
  echo ""
  echo "本脚本不会粗暴卸载旧内核。"
  echo "推荐流程是："
  echo "1. 安装带 BBRplus 的新内核"
  echo "2. 保留旧内核作为回滚"
  echo "3. 重启进入新内核"
  echo "4. 再次执行本脚本启用 bbrplus"
  echo ""
  echo "你后续可以把这里扩展成：自动下载并安装特定发行版的 BBRplus 内核包。"
  exit 2
fi
