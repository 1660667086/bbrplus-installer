#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

apply_bbrplus() {
  write_bbrplus_sysctl
  color green "[完成] 已尝试启用 bbrplus"
  echo
  sysctl net.core.default_qdisc || true
  sysctl net.ipv4.tcp_congestion_control || true
}

main() {
  require_root
  local source
  source="$(parse_source_arg "$@")"

  print_basic_info
  echo

  if supports_bbrplus; then
    color green "[OK] 当前内核已支持 bbrplus，开始启用。"
    apply_bbrplus
    exit 0
  fi

  color yellow "[提示] 当前内核暂不支持 bbrplus。"

  if ! is_supported_os; then
    color red "[错误] 当前仅内置 Debian / Ubuntu / CentOS 风格流程，其它系统请自行扩展。"
    exit 2
  fi

  echo
  color blue "[信息] 准备进入支持 BBRplus 内核的安装流程。"
  color yellow "[提醒] 本项目不会主动卸载旧内核。"
  color yellow "[提醒] 安装新内核后，通常需要重启进入新内核，再重新执行本脚本。"
  echo

  if install_bbrplus_kernel_stub "${source}"; then
    color green "[完成] 内核安装流程执行结束。"
  else
    code=$?
    if [[ ${code} -eq 10 ]]; then
      color yellow "[待确认] 当前是安全模式，未自动下载历史内核源。"
      exit 10
    fi
    exit ${code}
  fi
}

main "$@"
