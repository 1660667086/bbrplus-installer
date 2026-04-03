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

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    color red "[错误] 请使用 root 运行此脚本"
    exit 1
  fi
}

get_os_id() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

get_os_name() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-${NAME:-unknown}}"
  else
    echo "unknown"
  fi
}

get_arch() {
  uname -m
}

get_kernel() {
  uname -r
}

supports_bbrplus() {
  local available_cc
  available_cc="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
  echo " ${available_cc} " | grep -qi ' bbrplus '
}

is_supported_os() {
  local os_id
  os_id="$(get_os_id)"
  [[ "${os_id}" == "debian" || "${os_id}" == "ubuntu" ]]
}

print_basic_info() {
  color blue "系统: $(get_os_name)"
  color blue "架构: $(get_arch)"
  color blue "内核: $(get_kernel)"
}

install_bbrplus_kernel_stub() {
  color yellow "[提示] 当前准备进入安装支持 BBRplus 的内核流程。"
  echo
  echo "这里建议你后续接入你自己信任的 BBRplus 内核来源。"
  echo "例如："
  echo "- 你自己维护的 .deb 包下载地址"
  echo "- 你自己的 GitHub Release"
  echo "- 固定版本的内核安装脚本"
  echo
  echo "当前版本为了安全，不默认下载未知第三方内核。"
  echo "但保留了完整流程入口，方便你后续补上。"
  return 10
}
