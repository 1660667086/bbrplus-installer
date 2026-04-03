#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  color yellow "[提示] 当前不是 root，检测可继续，但部分信息可能受限。"
fi

available_cc="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
current_cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
current_qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"

print_basic_info
echo
color blue "当前队列调度: ${current_qdisc:-unknown}"
color blue "当前拥塞控制: ${current_cc:-unknown}"
color blue "可用拥塞控制: ${available_cc:-unknown}"
echo

if supports_bbrplus; then
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
  if is_supported_os; then
    echo "当前系统属于已内置流程支持范围（Debian/Ubuntu）。"
  else
    echo "当前系统暂未内置自动安装流程。"
  fi
fi
