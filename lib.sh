  fi


  case "${os_id}" in
    debian)
      [[ "${version}" -ge 8 ]]
      ;;
    ubuntu)
      [[ "${version}" -ge 14 ]]
      ;;
    centos|rhel|rocky|almalinux)
      [[ "${version}" -ge 6 ]]
      ;;
    *)
      return 1
      ;;
  esac
}


write_bbrplus_sysctl() {
  local conf_file="/etc/sysctl.d/99-bbrplus.conf"
  cat >"${conf_file}" <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbrplus
EOF
  sysctl --system >/dev/null
  color green "[完成] 已写入 ${conf_file}"
}


parse_source_arg() {
  local source="${DEFAULT_SOURCE}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        shift
        source="${1:-${DEFAULT_SOURCE}}"
        ;;
      --source=*)
        source="${1#*=}"
        ;;
    esac
    shift || true
  done
  echo "${source}"
}


ensure_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    color red "[错误] 缺少命令: ${cmd}"
    return 1
  }
}


update_grub_safely() {
  if command -v update-grub >/dev/null 2>&1; then
    update-grub || true
  elif command -v grub2-mkconfig >/dev/null 2>&1 && [[ -d /boot/grub2 ]]; then
    grub2-mkconfig -o /boot/grub2/grub.cfg || true
  fi
}



install_bbrplus_kernel_from_cx9208() {
  local os_id arch_tag version kernel_version workdir
  os_id="$(get_os_id)"
  arch_tag="$(get_arch_tag)"
  version="$(get_os_version_major)"
  kernel_version="4.14.129-bbrplus"
  workdir="/tmp/bbrplus-cx9208.$$"

  color yellow "[警告] 你正在使用 legacy 源: cx9208/Linux-NetSpeed"
  color yellow "[警告] 该源较老，仅建议测试环境使用。"
  echo

  mkdir -p "${workdir}"
  cd "${workdir}"

  if is_debian_like; then
    ensure_cmd wget
    ensure_cmd dpkg

    local header_pkg="linux-headers-${kernel_version}.deb"
    local image_pkg="linux-image-${kernel_version}.deb"
    local base_url="${CX9208_BASE_URL}/bbrplus/debian-ubuntu/${arch_tag}"

    color blue "[信息] 开始下载 Debian/Ubuntu 历史内核包..."
    wget -O "${header_pkg}" "${base_url}/${header_pkg}"
    wget -O "${image_pkg}" "${base_url}/${image_pkg}"

    color blue "[信息] 开始安装内核包（保留旧内核，不自动删除）..."
    dpkg -i "${header_pkg}"
    dpkg -i "${image_pkg}"
    update_grub_safely
  elif is_centos_like; then
    ensure_cmd wget
    ensure_cmd yum

    local rpm_pkg="kernel-${kernel_version}.rpm"
    local major="${version}"
    local base_url="${CX9208_BASE_URL}/bbrplus/centos/${major}"

    color blue "[信息] 开始下载 CentOS 历史内核包..."
    wget -O "${rpm_pkg}" "${base_url}/${rpm_pkg}"

    color blue "[信息] 开始安装内核包（保留旧内核，不自动删除）..."
    yum install -y "./${rpm_pkg}"
    update_grub_safely
  else
    color red "[错误] cx9208 源当前仅处理 Debian/Ubuntu/CentOS 风格系统。"
    return 2
  fi

  color green "[完成] 历史 BBRplus 内核包安装流程已执行。"
  color yellow "[提醒] 本脚本没有删除旧内核。"
  color yellow "[提醒] 你需要重启进入新内核后，再重新执行 install.sh 启用 bbrplus。"
  return 0
}

install_bbrplus_kernel_stub() {
  local source="${1:-${DEFAULT_SOURCE}}"

  color blue "[信息] 当前安装源: ${source}"

  if ! supports_bbrplus_install_policy; then
    color red "[错误] 当前系统不在内置 BBRplus 安装策略范围内。"
    echo "支持策略参考 cx9208 旧逻辑，当前仅放行："
    echo "- Debian >= 8"
    echo "- Ubuntu >= 14"
    echo "- CentOS/RHEL系 >= 6"
    echo "- 架构: x64/x32"
    return 2
  fi

  case "${source}" in
    safe)
      color yellow "[提示] safe 模式只做兼容判断，不自动下载历史内核。"
      echo "如果你确认要使用历史源，请执行："
      echo "bash install.sh --source cx9208"
      return 10
      ;;
    cx9208)
      install_bbrplus_kernel_from_cx9208
      ;;
    *)
      color red "[错误] 未知安装源: ${source}"
      echo "当前支持的 --source: safe, cx9208"
      return 3
      ;;
  esac
}
