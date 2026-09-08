![GitHub License](https://img.shields.io/github/license/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github) ![GitHub Tag](https://img.shields.io/github/v/release/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Johnn-Lee/luci-app-auth-thu/total?style=for-the-badge&logo=github) ![GitHub Repo stars](https://img.shields.io/github/stars/Johnn-Lee/luci-app-auth-thu?style=for-the-badge&logo=github)

# LuCI App Auth THU

在 OpenWrt 上使用 [GoAuthing](https://github.com/z4yx/GoAuthing) 认证清华大学校园网。

## 环境要求

- OpenWrt / ImmortalWrt
- 已安装 LuCI

## 功能

- 网页配置认证账号
- 服务状态与核心版本监控
- 在线下载 GoAuthing 核心 (自动检测架构)
- 认证日志

## 安装和更新

### A. 从软件源安装 (推荐)

1. 添加源

```shell
# 只需运行一次, 自动识别 opkg / apk
wget -O - https://github.com/Johnn-Lee/luci-app-auth-thu/raw/refs/heads/master/feed.sh | ash
```

如需手动添加:

```shell
# opkg (21.02 ~ 23.05)
wget -O /tmp/key-build.pub https://johnn-lee.github.io/luci-app-auth-thu/opkg/key-build.pub
opkg-key add /tmp/key-build.pub
echo "src/gz auth-thu https://johnn-lee.github.io/luci-app-auth-thu/opkg" >> /etc/opkg/customfeeds.conf
opkg update
# apk (24.10+)
wget -O /etc/apk/keys/auth-thu.pem https://johnn-lee.github.io/luci-app-auth-thu/apk/public-key.pem
echo "https://johnn-lee.github.io/luci-app-auth-thu/apk/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
apk update
```

2. 安装

```shell
# for opkg
opkg install luci-app-auth-thu
# for apk
apk add luci-app-auth-thu
```

### B. 从发行版安装

从 [releases](https://github.com/Johnn-Lee/luci-app-auth-thu/releases) 下载对应的软件包并安装, 也可以在 LuCI 的`软件包`菜单上传安装。

```shell
# for opkg
opkg install /tmp/luci-app-auth-thu-*.ipk
# for apk
apk add --allow-untrusted /tmp/luci-app-auth-thu-*.apk
```

## 卸载

```shell
# for opkg
opkg remove luci-app-auth-thu
# for apk
apk del luci-app-auth-thu
```

## 如何使用

1. 进入 LuCI 的`服务 -> Auth THU`。
2. 在`Global Settings`中填写认证用户名和密码, 勾选`Enable`。
3. 点击`Download`下载最新 GoAuthing 核心, 或使用`Auto Generate URL`生成下载地址后手动修改。
4. 保存并应用, 服务自动启动。
5. 在`Logs`中查看认证日志。

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

编译结果可以在`bin/packages/your_architecture/auth-thu`内找到。

## 依赖

- luci-base
- GoAuthing 核心由 LuCI 界面在线下载, 支持 arm, arm64, x86_64, mips, riscv64 等架构

## 贡献者

[![贡献者](https://contrib.rocks/image?repo=Johnn-Lee/luci-app-auth-thu)](https://github.com/Johnn-Lee/luci-app-auth-thu/graphs/contributors)

## 特别感谢

- [@z4yx](https://github.com/z4yx)
- [@stevenjoezhang](https://github.com/stevenjoezhang)
