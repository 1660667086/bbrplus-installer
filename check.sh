#!/usr/bin/env bash
set -euo pipefail

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

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  color yellow "[提示] 当前不是 root，检测可继续，但部分信息可能受限。"
fi

kernel="$(uname -r)"
os_name="unknown"
arch="$(uname -m)"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  os_name="${PRETTY_NAME:-$NAME}"
fi

available_cc="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
current_cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
current_qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"

color blue "系统: ${os_name}"
color blue "架构: ${arch}"
color blue "内核: ${kernel}"
echo
color blue "当前队列调度: ${current_qdisc:-unknown}"
color blue "当前拥塞控制: ${current_cc:-unknown}"
color blue "可用拥塞控制: ${available_cc:-unknown}"
echo

if echo " ${available_cc} " | grep -qi ' bbrplus '; then
  color green "[OK] 当前内核已支持 bbrplus"
  if [[ "${current_cc}" == "bbrplus" ]]; then
    color green "[OK] 当前已经在使用 bbrplus"
  else
    color yellow "[提示] 当前支持 bbrplus，但尚未启用"
    echo "可执行: bash install.sh"
  fi
else
  color red "[未支持] 当前内核没有检测到 bbrplus"
  echo "这通常意味着需要安装支持 BBRplus 的内核，然后重启进入新内核。"
  echo "注意：这不等于必须卸载旧内核。旧内核可以保留作为回滚项。"
fi
