# sgnur-packages

**sgnay 的个人 [NUR](https://github.com/nix-community/NUR) 仓库**

![Build and populate cache](https://github.com/sgnay/sgnur-packages/workflows/Build%20and%20populate%20cache/badge.svg)

## 包含的包

| 包名 | 描述 | 状态 |
|---|---|---|
| `univpn` | Leagsoft UniVPN 客户端 | ✅ 可用 |
| `univpn-nixos-module` | UniVPN NixOS 模块（`services.univpn.enable`） | ✅ 可用 |
| `sunloginclient` | 向日葵远程控制客户端 (AweSun Client) | ✅ 可用 |
| `sunloginclient-nixos-module` | 向日葵远程控制 NixOS 模块（`services.sunloginclient.enable`） | ✅ 可用 |
| `velotype` | [Velotype](https://github.com/manyougz/velotype) — 基于 Rust + GPUI 的原生 Markdown 编辑器 (WYSIWYG/源码) | ✅ 可用 |
| `goose-desktop` | [Goose Desktop](https://github.com/aaif-goose/goose) — Goose AI Agent 桌面图形应用 | ✅ 可用 |
| `fcitx5-windinput` | [清风输入法 (WindInput)](https://windinput.com) — Fcitx5 输入法引擎（服务/设置/addon/词库全部源码构建） | ✅ 可用 |
| `fcitx5-windinput-nixos-module` | 清风输入法 NixOS 模块（`services.fcitx5-windinput.enable`） | ✅ 可用 |
| `fcitx5-windinput-home-module` | 清风输入法 Home Manager 模块（注册 addon + 环境变量） | ✅ 可用 |

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

# 运行 Goose Desktop
nix run github:sgnay/sgnur-packages#goose-desktop

# 运行清风输入法设置程序
nix run github:sgnay/sgnur-packages#fcitx5-windinput
```

#### 作为 NixOS 模块启用

```nix
{
  imports = [
    inputs.sgnur-packages.nixosModules.univpn
    inputs.sgnur-packages.nixosModules.sunloginclient
    inputs.sgnur-packages.nixosModules.fcitx5-windinput
  ];
  services.univpn.enable = true;
  services.sunloginclient.enable = true;
  services.fcitx5-windinput.enable = true;
}
```

#### 清风输入法（Home Manager，推荐）

Home Manager 模块会把包注册进 `i18n.inputMethod.fcitx5.addons`，并设置
`WIND_INPUT_SERVICE` / `WIND_INPUT_SETTING`，让 addon 能找到服务与设置程序：

```nix
{
  imports = [ inputs.sgnur-packages.homeModules.fcitx5-windinput ];
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };
}
```

安装后重启 fcitx5（`fcitx5 -rd`），在 `fcitx5-configtool` 的输入法列表中添加「清风输入法」。
Wayland（niri）下候选窗走 `input-method-v2` popup，不要设置 `QT_IM_MODULE` / `GTK_IM_MODULE`。

### 通过 NUR

如果你已配置 [NUR](https://github.com/nix-community/NUR)：

```nix
{ pkgs, ... }:
{
  # 示例：通过 NUR 引入包
  environment.systemPackages = [
    pkgs.nur.repos.sgnay.univpn
    pkgs.nur.repos.sgnay.sunloginclient
    pkgs.nur.repos.sgnay.fcitx5-windinput
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
    pkgs'.sunloginclient
  ];
}
```

## 开发

```bash
# 构建单个包
nix build .#univpn
nix build .#sunloginclient
nix build .#fcitx5-windinput

# 检查评估
nix-env -f . -qa \* --meta --xml --drv-path --show-trace
```

## 项目结构

```
:.
├── flake.nix              # Flake 入口
├── default.nix            # 包集合入口
├── overlay.nix            # nixpkgs overlay
├── ci.nix                 # CI 构建定义
├── pkgs/
│   ├── univpn/            # UniVPN 包
│   ├── sunloginclient/    # 向日葵远程控制客户端包
│   └── fcitx5-windinput/  # 清风输入法（源码构建）
├── nixos-modules/
│   ├── default.nix        # NixOS 模块索引
│   ├── univpn.nix         # UniVPN NixOS 模块
│   ├── sunloginclient.nix # 向日葵远程控制 NixOS 模块
│   └── fcitx5-windinput.nix # 清风输入法 NixOS 模块
├── home-modules/
│   ├── default.nix        # Home Manager 模块索引
│   └── fcitx5-windinput.nix # 清风输入法 HM 模块
├── lib/                   # 库函数
└── overlays/              # Overlays
```

## 许可

MIT License — 本仓库基于 [nur-packages-template](https://github.com/nix-community/nur-packages-template)（Copyright (c) 2018 Francesco Gazzetta）。
