# sgnur-packages — Agent 理解文档

## 项目概述

`sgnur-packages` 是用户 **sgnay** 的个人 [NUR (Nix User Repository)](https://github.com/nix-community/NUR) 仓库，基于官方模板 [`nur-packages-template`](https://github.com/nix-community/nur-packages-template) 创建。

- **GitHub**: <https://github.com/sgnay/sgnur-packages>
- **许可**: MIT License（模板原版权属 Francesco Gazzetta）

## 项目结构

```
sgnur-packages/
├── flake.nix                  # Nix Flake 入口，暴露 legacyPackages / packages / nixosModules
├── flake.lock                 # Flake 锁定文件（nixpkgs-unstable）
├── default.nix                # 主入口，返回 packages、lib、nixosModules、overlays
├── overlay.nix                # nixpkgs overlay
├── ci.nix                     # CI 构建定义
├── .github/workflows/build.yml # GitHub Actions CI 配置（已配置 nurRepo: sgnur-packages）
├── pkgs/
│   ├── univpn/                # UniVPN 客户端包
│   │   ├── default.nix
│   │   └── univpn-linux-64-10781.19.0.1214.zip
│   └── nyaterm/               # NyaTerm — 现代远程终端工作区
│       ├── default.nix
│       └── Cargo.lock
├── nixos-modules/
│   ├── default.nix            # NixOS 模块集合
│   └── univpn.nix             # UniVPN NixOS 模块（使用 pkgs.univpn）
├── lib/
│   └── default.nix            # 库函数（当前为空占位）
├── overlays/
│   └── default.nix            # overlays 集合（当前为空）
├── LICENSE
├── README.md                  # 已重写为项目真实描述
└── agents.md                  # ← 本文件
```

## 当前包含的组件

### 1. UniVPN 包 (`pkgs/univpn`)

- **版本**: `10781.19.0.1214`
- **描述**: Leagsoft UniVPN 客户端的 Nix 打包
- **参数**: `src` — zip 文件路径，默认为 `./univpn-linux-64-10781.19.0.1214.zip`
- **构建**: 解压 zip → 跳过 `.run` 自解压头部 → 解压 tar.gz → 设置可执行权限
- **输出**: `UniVPN`, `serviceclient/UniVPNCS`, `promote/UniVPNPromoteService`, `UniVPNUpdate`, `certificate/`
- **注册**: `default.nix` → `pkgs.callPackage ./pkgs/univpn { }`

### 2. UniVPN NixOS 模块 (`nixos-modules/univpn.nix`)

- **启用**: `services.univpn.enable`
- **功能**: 部署到 `/usr/local/UniVPN/`、启动 wrapper、setuid 权限、Qt5 清理、桌面入口
- **注册**: `nixos-modules/default.nix`

### 3. NyaTerm 包 (`pkgs/nyaterm`)

- **版本**: `1.1.13`（基于 Git 提交 `2f0059d6`，上游无标签）
- **描述**: [NyaTerm](https://nyaterm.app) — 基于 Tauri 2 + React + Rust 的现代远程终端工作区
- **功能**: SSH 客户端、本地终端、Telnet、串口、SFTP、OTP、SSH 隧道、AI 辅助、加密同步
- **架构**:
  - **前端**: React 19 + TypeScript + Vite 7（pnpm 构建，644 个 npm 包）
  - **后端**: Rust + Tauri 2（Russh SSH、portable-pty 等，882 个 crate）
- **构建方式**:
  1. `fetchPnpmDeps` 预取所有 pnpm 依赖
  2. `pnpmConfigHook` 在 configure 阶段安装 node_modules
  3. `preBuild` 运行 `pnpm build` 构建前端 → 生成 `dist/`
  4. `buildRustPackage` + `cargoLock.lockFile` 编译 Rust 后端
- **系统依赖** (buildInputs): `webkitgtk_4_1`, `libsoup_3`, `gtk3`, `glib`, `cairo`, `gdk-pixbuf`, `pango`, `atk`, `libxcb`, `libx11`, `libxkbcommon`, `freetype`, `fontconfig`, `dbus`, `openssl`, `zlib`, `brotli`, `libappindicator-gtk3`, `librsvg`, `udev`
- **特殊处理**:
  - `doCheck = false` — 沙箱中并发数据库访问导致测试失败
  - `cargoLock.lockFile = ./Cargo.lock` — Cargo.lock 从上游复制到包目录
  - 使用 `buildAndTestSubdir = "src-tauri"` 确保 cargo 在正确的目录构建
- **注册**: `default.nix` → `pkgs.callPackage ./pkgs/nyaterm { }`

### 4. CI 流水线 (`.github/workflows/build.yml`)

- **触发器**: PR、push 到 main/master、每日定时（02:51）、手动触发
- **矩阵**: `nixpkgs-unstable`, `nixos-unstable`, `nixos-26.05`
- **nurRepo**: `sgnur-packages`
- **cachix**: 未配置（默认跳过）

## 使用方式

```bash
# 通过 Flake 运行 UniVPN
nix run github:sgnay/sgnur-packages#univpn

# 通过 Flake 运行 NyaTerm
nix run github:sgnay/sgnur-packages#nyaterm

# 通过 NixOS 模块启用 UniVPN
# configuration.nix:
{
  imports = [ inputs.sgnur-packages.nixosModules.univpn ];
  services.univpn.enable = true;
}

# 通过 overlay 使用
nix-build -E 'with import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; }; univpn'

# 本地构建
nix-build -A nyaterm
./result/bin/nyaterm
```

## 已完成的改进

| 项目 | 状态 | 说明 |
|---|---|---|
| CI nurRepo 配置 | ✅ | 改为 `sgnur-packages` |
| CI cachixName 配置 | ✅ | 占位符改为 `unused`，缓存步骤默认跳过 |
| 清理 `pkgs/example-package` | ✅ | 已删除 |
| Zip 文件外部化 | ✅ | 放入 `pkgs/univpn/`，包定义接受 `src` 参数 |
| NixOS 模块引用包 | ✅ | 改为使用 `pkgs.univpn`，消除构建逻辑重复 |
| 注册 univpn 到 default.nix | ✅ | 通过 `pkgs.callPackage` 加载 |
| 重写 README.md | ✅ | 替换为项目真实描述 |
| 打包 nyaterm | ✅ | NyaTerm — 现代远程终端工作区 |

## 后续建议

| 项目 | 优先级 | 说明 |
|---|---|---|
| 配置 Cachix 缓存 | 低 | 如需加速 CI，创建 Cachix 账号并在 GitHub Secrets 中设置密钥 |
| 补充 `lib/` 函数 | 低 | 当前为空，有通用 Nix 函数时可放入 |
| 补充 `overlays/` | 低 | 当前为空，有额外 overlay 时可放入 |
| nyaterm NixOS 模块 | 中 | 可创建 NixOS 模块以集成桌面文件、DBus 服务等 |
| nyaterm 版本更新 | 持续 | 上游无标签，需手动更新提交哈希和 Cargo.lock |