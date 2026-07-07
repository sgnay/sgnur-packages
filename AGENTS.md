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
│   └── univpn/                # UniVPN 客户端包
│       ├── default.nix        # 包定义（接受 src 参数）
│       └── univpn-linux-64-10781.19.0.1214.zip  # 供应商提供的 zip 包
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
- **参数**:
  - `src` — zip 文件路径，默认为 `./univpn-linux-64-10781.19.0.1214.zip`（包目录下的本地文件）
- **构建过程**: 解压 zip → 跳过 `.run` 自解压头部（258 行）→ 解压 tar.gz → 设置可执行权限
- **输出内容**:
  - `UniVPN` — 主 GUI 程序
  - `serviceclient/UniVPNCS` — 服务端组件
  - `promote/UniVPNPromoteService` — 提权服务
  - `UniVPNUpdate` — 更新程序
  - `certificate/` — 证书目录
- **依赖**（构建时）: `unzip`, `gzip`, `binutils`
- **注册于**: `default.nix` 中通过 `pkgs.callPackage ./pkgs/univpn { }` 加载

### 2. UniVPN NixOS 模块 (`nixos-modules/univpn.nix`)

- **启用选项**: `services.univpn.enable`
- **使用**: `pkgs.univpn` 包（而非内联构建）
- **功能**:
  - 将 UniVPN 软件包部署到 `/usr/local/UniVPN/`
  - 生成 `univpn` 启动 wrapper（设置 `LD_LIBRARY_PATH` 和 `QT_PLUGIN_PATH`）
  - 生成 `univpn-stop` / `univpn-restart` 辅助命令
  - 生成 `.desktop` 桌面入口
  - 设置 setuid 权限位（`UniVPNCS`, `UniVPNPromoteService`, `UniVPNUpdate`）
  - 清理捆绑的 Qt5 原生库，改为使用 nixpkgs 提供的 Qt5
  - 通过 systemd tmpfiles 确保 `/usr/bin/pgrep` 可用
  - 自动创建日志、证书目录并设置权限
- **运行时依赖**:
  - nixpkgs Qt5 (`qtbase`, `qtsvg`)
  - X11 库 (`libxcb`, `libx11`, `libxkbcommon`, `fontconfig`, `freetype`, `libglvnd`)
  - `procps`（提供 `pgrep`）
  - `zstd`

### 3. CI 流水线 (`.github/workflows/build.yml`)

- **触发器**: PR、push 到 main/master、每日定时（02:51）、手动触发
- **矩阵构建**: 三个 nixpkgs 分支（`nixpkgs-unstable`, `nixos-unstable`, `nixos-26.05`）
- **nurRepo**: 已配置为 `sgnur-packages`
- **cachix**: 未配置（默认跳过缓存步骤）
- **步骤**:
  1. Checkout + 安装 Nix（启用 flakes）
  2. 可选：配置 Cachix 缓存
  3. 检查 evaluation
  4. 构建 `ci.nix` 中的 `cacheOutputs`
  5. 触发 NUR 更新

## 使用方式

```bash
# 通过 Flake 运行
nix run github:sgnay/sgnur-packages#univpn

# 通过 NixOS 模块启用
# configuration.nix:
{
  imports = [ inputs.sgnur-packages.nixosModules.univpn ];
  services.univpn.enable = true;
}

# 通过 overlay 使用
nix-build -E 'with import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; }; univpn'
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

## 后续建议

| 项目 | 优先级 | 说明 |
|---|---|---|
| 配置 Cachix 缓存 | 低 | 如需加速 CI，创建 Cachix 账号并在 GitHub Secrets 中设置密钥 |
| 补充 `lib/` 函数 | 低 | 当前为空，有通用 Nix 函数时可放入 |
| 补充 `overlays/` | 低 | 当前为空，有额外 overlay 时可放入 |