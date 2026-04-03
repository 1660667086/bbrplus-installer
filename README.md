# bbrplus-installer

一套尽量保守的一键式 BBRplus 安装脚本模板：

- **不主动卸载旧内核**
- **优先检测当前内核是否已支持 BBRplus**
- **仅在确认环境支持时启用**
- **保留回滚思路**

> 重要：BBRplus 一般依赖特定内核支持，不是单纯改个 sysctl 就能在所有机器生效。
> 
> 这个项目的目标不是“所有机器无脑秒开 BBRplus”，而是：
> **尽量安全地检测、启用、提示安装支持内核，并保留回滚能力。**

## 适用场景

- Debian / Ubuntu
- KVM / 独立服务器 / 支持自定义内核的 VPS
- 想保留旧内核，不希望粗暴删除原有内核

## 不适用场景

- OpenVZ / 部分 LXC 容器
- 云厂商限制自定义内核的环境
- 指望“不换内核也强开 BBRplus”的场景

## 仓库内容

- `check.sh`：检查当前系统、内核和拥塞控制支持情况
- `install.sh`：启用 BBRplus；若当前内核不支持，则给出后续安装支持内核的提示
- `rollback.sh`：切回 BBR 或 CUBIC

## 快速使用

先检测：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/1660667086/bbrplus-installer/main/check.sh)
```

直接尝试启用：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/1660667086/bbrplus-installer/main/install.sh)
```

回滚：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/1660667086/bbrplus-installer/main/rollback.sh)
```

## 工作原理

### 情况 1：当前内核已支持 bbrplus
脚本会直接写入：

```conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbrplus
```

然后执行：

```bash
sysctl --system
```

### 情况 2：当前内核不支持 bbrplus
脚本不会强行乱改系统，而是：

- 明确提示当前内核不支持
- 保留旧内核
- 提示你安装带 BBRplus 的内核后再启用

## 风险提示

- BBRplus **需要内核支持**
- 不同线路效果差异很大
- 不是所有 VPS 都允许你切换内核
- 开启后如果异常，可执行 `rollback.sh`

## 建议

如果你后续要把它做成真正的一键安装项目，建议再加入：

- 针对 Debian/Ubuntu 的内核包安装逻辑
- grub 默认启动项管理
- 自动识别 x86_64 / arm64
- 安装后重启前二次确认
- 更完整的日志输出

## 免责声明

请先在测试机验证后再上生产环境。任何内核相关操作都有风险。
