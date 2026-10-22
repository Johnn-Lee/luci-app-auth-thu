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

安装脚本会自动检测系统使用的是 opkg 还是 apk，并从 GitHub Releases 下载对应的最新软件包。apk 系统首次安装时，脚本会核对固定公钥的 SHA-256，将项目公钥导入 `/etc/apk/keys/auth-thu.pem`，然后正常验签安装；不会关闭签名检查。

```shell
wget -O - https://raw.githubusercontent.com/Johnn-Lee/luci-app-auth-thu/master/feed.sh | ash
```

以后再次运行同一条命令即可安装最新 Release。

### B. 从 GitHub Releases 手动安装

从 [Releases](https://github.com/Johnn-Lee/luci-app-auth-thu/releases) 下载对应的软件包。IPK 可以直接在 LuCI 的“软件包”页面上传安装；APK 需要先导入本项目公钥，之后才可以直接上传安装。

opkg 系统下载 `luci-app-auth-thu.ipk`：

```shell
opkg install /tmp/luci-app-auth-thu.ipk
```

apk 系统下载 `luci-app-auth-thu.apk` 和 `auth-thu.pem`。首次安装先核对并导入公钥：

```shell
echo '5e016e0c1d881bbecc1daacfa3114fa75aaa2456e3a5906fc03553a6b4f01a2d  /tmp/auth-thu.pem' | sha256sum -c - &&
mkdir -p /etc/apk/keys &&
cp /tmp/auth-thu.pem /etc/apk/keys/auth-thu.pem &&
chmod 0644 /etc/apk/keys/auth-thu.pem &&
apk add /tmp/luci-app-auth-thu.apk
```

> GitHub Release 只在推送 `v*` 版本标签时自动创建。普通 master 分支提交只执行构建测试，并将 `.ipk` / `.apk` 保存在对应 GitHub Actions run 的 Artifacts 中。

第三方签名不会自动获得原厂固件信任，第一次导入公钥是必要步骤。公钥导入后，后续 APK 更新不再需要额外操作。IPK 的标准信任机制是软件源索引签名，本地 IPK 安装不需要给包添加 APK 式签名。

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
3. 点击“Download”下载最新 GoAuthing 核心，或使用“Auto Generate URL”生成下载地址后手动修改。下载使用当前表单中的地址，无需预先保存。只有包含 `${version}` 的地址才需要访问 GitHub API。
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

每次发布新 Release 前提升 `luci-app-auth-thu/Makefile` 中的 `PKG_VERSION`；Git 标签本身不会改变包版本。创建并推送与 `PKG_VERSION` 一致的标签，例如：

```shell
git tag v1.1.1
git push origin v1.1.1
```

GitHub Actions 构建成功后会自动创建对应的 GitHub Release，并上传：

- `luci-app-auth-thu.ipk`
- `luci-app-auth-thu.apk`
- `auth-thu.pem`：APK 验签公钥
- `SHA256SUMS`

### APK 签名配置

本仓库已配置固定的 `APK_SIGNING_KEY` Actions Secret，只有公钥位于 `keys/auth-thu.pem`。每次构建都对 APKv3 单包签名，并验证：正确公钥通过、空信任库拒绝、错误公钥拒绝、篡改包拒绝。缺少 Secret 或私钥与仓库公钥不匹配时，构建失败，不发布未签名 APK。

其他 fork 需要自行生成并备份 ECDSA P-256 私钥，将私钥存入自己的 `APK_SIGNING_KEY` Secret，替换 `keys/auth-thu.pem`，并同步更新 `feed.sh` 与本文中的公钥 SHA-256。私钥不能提交到 Git。

### 自动验证

`sh tests/run.sh` 运行凭据传参、下载失败保留旧核心、当前表单 URL、安装器公钥引导和错误提示回归测试。GitHub Actions 还分别使用官方 24.10/25.12 根文件系统执行 IPK/APK 隔离安装，APK 使用正常验签。隔离测试禁用或延后安装后脚本；真实路由器上的 procd/LuCI 和校园网认证仍需实机验证。

## 依赖

- luci-base
- GoAuthing 核心由 LuCI 界面在线下载，支持 arm、arm64、x86_64、mips、riscv64 等架构

## 特别感谢

- [@z4yx](https://github.com/z4yx)
- [@stevenjoezhang](https://github.com/stevenjoezhang)
