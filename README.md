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
- `install.sh`：自动检测并尝试启用 BBRplus；当前内核不支持时可进入安装支持内核流程
- `rollback.sh`：切回 BBR 或 CUBIC
- `lib.sh`：公共函数，包含系统识别、内核支持检测、root 检查等

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

## 当前一键逻辑

现在的 `install.sh` 会按下面流程执行：

1. 检测系统（Debian / Ubuntu）
2. 检测架构与当前内核
3. 检测当前内核是否已支持 `bbrplus`
4. 若已支持：直接写入 sysctl 并启用
5. 若不支持：
   - 优先提示当前环境限制
   - 尝试进入“安装支持 BBRplus 的内核”流程
   - 保留旧内核，不主动删除
   - 提示重启后再次执行启用

## 重要说明

由于不同发行版、不同机器、不同第三方 BBRplus 内核源差异非常大，**真正的“自动安装支持 BBRplus 的内核”部分需要你后续绑定一个你信任的内核来源**。

也就是说，这个仓库现在已经具备：

- 一键检测
- 一键启用
- 一键回滚
- 一键进入安装流程骨架

但“安装哪个 BBRplus 内核包”这件事，最好由你指定来源后再固化。

## 下一步建议

如果你准备长期维护这个项目，建议继续补：

- 你自己信任的 BBRplus 内核包源
- grub 默认启动项自动切换
- 重启后自动二次检测
- 自动验证 `sysctl net.ipv4.tcp_congestion_control`
- 更完整的失败回退提示

## 免责声明

请先在测试机验证后再上生产环境。任何内核相关操作都有风险。
