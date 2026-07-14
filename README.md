# sgnur-packages

**sgnay 的个人 [NUR](https://github.com/nix-community/NUR) 仓库**

![Build and populate cache](https://github.com/sgnay/sgnur-packages/workflows/Build%20and%20populate%20cache/badge.svg)

## 包含的包

| 包名 | 描述 | 状态 |
|---|---|---|
| `univpn` | Leagsoft UniVPN 客户端 | ✅ 可用 |
| `univpn-nixos-module` | UniVPN NixOS 模块（`services.univpn.enable`） | ✅ 可用 |
| `nyaterm` | [NyaTerm](https://nyaterm.app) — 现代远程终端工作区（SSH / SFTP / Telnet / Serial） | ✅ 可用 |
| `nyaterm.desktop` | NyaTerm 桌面入口文件（含图标，可从应用菜单启动） | ✅ 自动安装 |
| `omp` | [Oh My Pi](https://github.com/can1357/oh-my-pi) — 终端原生 AI 编程助手 | ✅ 可用 |
| `sunloginclient` | 向日葵远程控制客户端 (AweSun Client) | ✅ 可用 |
| `sunloginclient-nixos-module` | 向日葵远程控制 NixOS 模块（`services.sunloginclient.enable`） | ✅ 可用 |

## 使用方式

### 通过 Flake

在 `flake.nix` 中添加输入：

```nix
{
  inputs.sgnur-packages.url = "github:sgnay/sgnur-packages";
}
```

#### 运行包

```bash
# 运行 UniVPN
nix run github:sgnay/sgnur-packages#univpn

# 运行 NyaTerm
nix run github:sgnay/sgnur-packages#nyaterm

# 运行 Oh My Pi
nix run github:sgnay/sgnur-packages#omp

# 运行 Sunlogin (AweSun)
nix run github:sgnay/sgnur-packages#sunloginclient
```

#### 作为 NixOS 模块启用

```nix
{
  imports = [
    inputs.sgnur-packages.nixosModules.univpn
    inputs.sgnur-packages.nixosModules.sunloginclient
  ];
  services.univpn.enable = true;
  services.sunloginclient.enable = true;
}
```

### 通过 NUR

如果你已配置 [NUR](https://github.com/nix-community/NUR)：

```nix
{ pkgs, ... }:
{
  # 示例：通过 NUR 引入包
  environment.systemPackages = [
    pkgs.nur.repos.sgnay.univpn
    pkgs.nur.repos.sgnay.nyaterm
    pkgs.nur.repos.sgnay.omp
    pkgs.nur.repos.sgnay.sunloginclient
  ];
}
```

### 通过 Overlay

```nix
{ config, pkgs, ... }:
let
  overlays = [ (import ./overlay.nix) ];
  pkgs' = import <nixpkgs> { inherit overlays; };
in {
  environment.systemPackages = [
    pkgs'.univpn
    pkgs'.nyaterm
    pkgs'.omp
    pkgs'.sunloginclient
  ];
}
```

## 开发

```bash
# 构建单个包
nix-build -A univpn
nix-build -A nyaterm
nix-build -A omp
nix-build -A sunloginclient

# 检查评估
nix-env -f . -qa \* --meta --xml --drv-path --show-trace
```

## 项目结构

```
.
├── flake.nix              # Flake 入口
├── default.nix            # 包集合入口
├── overlay.nix            # nixpkgs overlay
├── ci.nix                 # CI 构建定义
├── pkgs/
│   ├── univpn/            # UniVPN 包
│   ├── nyaterm/           # NyaTerm 包
│   ├── omp/               # Oh My Pi (omp) 包
│   └── sunloginclient/    # 向日葵远程控制客户端包
├── nixos-modules/
│   ├── default.nix        # NixOS 模块索引
│   ├── univpn.nix         # UniVPN NixOS 模块
│   └── sunloginclient.nix # 向日葵远程控制 NixOS 模块
├── lib/                   # 库函数
└── overlays/              # Overlays
```

## 许可

MIT License — 本仓库基于 [nur-packages-template](https://github.com/nix-community/nur-packages-template)（Copyright (c) 2018 Francesco Gazzetta）。