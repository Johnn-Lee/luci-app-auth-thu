![GitHub License](https://img.shields.io/github/license/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github) ![GitHub Tag](https://img.shields.io/github/v/release/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Johnn-Lee/luci-app-auth-thu/total?style=for-the-badge&logo=github) ![GitHub Repo stars](https://img.shields.io/github/stars/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github)

# LuCI App Auth THU

在 OpenWrt / ImmortalWrt 上使用 [GoAuthing](https://github.com/z4yx/GoAuthing) 认证清华大学校园网。

## 环境要求

- OpenWrt / ImmortalWrt
- 已安装 LuCI
- 使用 opkg 或 apk 软件包管理器

> OpenWrt 24.10 及以前使用 opkg；OpenWrt 25.12 及以后使用 apk。ImmortalWrt 请以系统实际提供的软件包管理器为准。

## 功能

- 网页配置认证账号
- 服务状态与核心版本监控
- 在线下载 GoAuthing 核心（自动检测架构）
- 认证日志

## 安装和更新

### A. 自动安装（推荐）

安装脚本会自动检测系统使用的是 opkg 还是 apk，并从 GitHub Releases 下载对应的最新软件包：

```shell
wget -O - https://raw.githubusercontent.com/Johnn-Lee/luci-app-auth-thu/master/feed.sh | ash
```

以后再次运行同一条命令即可安装最新 Release。

### B. 从 GitHub Releases 手动安装

从 [Releases](https://github.com/Johnn-Lee/luci-app-auth-thu/releases) 下载对应的软件包，也可以在 LuCI 的“软件包”页面上传安装。

opkg 系统下载 `luci-app-auth-thu.ipk`：

```shell
opkg install /tmp/luci-app-auth-thu.ipk
```

apk 系统下载 `luci-app-auth-thu.apk`：

```shell
apk add --allow-untrusted /tmp/luci-app-auth-thu.apk
```

> GitHub Release 只在推送 `v*` 版本标签时自动创建。普通 master 分支提交只执行构建测试，并将 `.ipk` / `.apk` 保存在对应 GitHub Actions run 的 Artifacts 中。

## 卸载

```shell
# opkg
opkg remove luci-app-auth-thu

# apk
apk del luci-app-auth-thu
```

## 如何使用

1. 进入 LuCI 的“服务 -> Auth THU”。
2. 在“Global Settings”中填写认证用户名和密码，勾选“Enable”。
3. 点击“Download”下载最新 GoAuthing 核心，或使用“Auto Generate URL”生成下载地址后手动修改。
4. 保存并应用，服务自动启动。
5. 在“Logs”中查看认证日志。

## 编译

```shell
# 添加源
echo "src-git auth-thu https://github.com/Johnn-Lee/luci-app-auth-thu.git;master" >> "feeds.conf.default"

# 更新并安装源
./scripts/feeds update -a
./scripts/feeds install -a

# 编译
make package/luci-app-auth-thu/compile
```

编译结果可以在 `bin/packages/your_architecture/auth-thu` 内找到。

本仓库的 GitHub Actions 同时验证：

- OpenWrt 24.10：构建 `.ipk`
- OpenWrt 25.12：构建 `.apk`

## 发布新版本

创建并推送以 `v` 开头的 Git 标签，例如：

```shell
git tag v1.1.0
git push origin v1.1.0
```

GitHub Actions 构建成功后会自动创建对应的 GitHub Release，并上传：

- `luci-app-auth-thu.ipk`
- `luci-app-auth-thu.apk`

## 依赖

- luci-base
- GoAuthing 核心由 LuCI 界面在线下载，支持 arm、arm64、x86_64、mips、riscv64 等架构

## 特别感谢

- [@z4yx](https://github.com/z4yx)
- [@stevenjoezhang](https://github.com/stevenjoezhang)
