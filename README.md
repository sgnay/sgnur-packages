# sgnur-packages

**sgnay 的个人 [NUR](https://github.com/nix-community/NUR) 仓库**

![Build and populate cache](https://github.com/sgnay/sgnur-packages/workflows/Build%20and%20populate%20cache/badge.svg)

## 包含的包

| 包名 | 描述 | 状态 |
|---|---|---|
| `univpn` | Leagsoft UniVPN 客户端 | ✅ 可用 |
| `univpn-nixos-module` | UniVPN NixOS 模块（`services.univpn.enable`） | ✅ 可用 |

## 使用方式

### 通过 Flake

在 `flake.nix` 中添加输入：

```nix
{
  inputs.sgnur-packages.url = "github:sgnay/sgnur-packages";
}
```

#### 运行 UniVPN

```bash
nix run github:sgnay/sgnur-packages#univpn
```

#### 作为 NixOS 模块启用

```nix
{
  imports = [ inputs.sgnur-packages.nixosModules.univpn ];
  services.univpn.enable = true;
}
```

### 通过 NUR

如果你已配置 [NUR](https://github.com/nix-community/NUR)：

```nix
{ pkgs, ... }:
{
  programs.univpn.enable = true;  # 假想，实际请参考模块配置
}
```

### 通过 Overlay

```nix
{ config, pkgs, ... }:
let
  overlays = [ (import ./overlay.nix) ];
  pkgs' = import <nixpkgs> { inherit overlays; };
in {
  environment.systemPackages = [ pkgs'.univpn ];
}
```

## 开发

```bash
# 构建所有包
nix-build -A univpn

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
│   └── univpn/            # UniVPN 包
├── nixos-modules/
│   └── univpn.nix         # UniVPN NixOS 模块
├── lib/                   # 库函数
└── overlays/              # Overlays
```

## 许可

MIT License — 本仓库基于 [nur-packages-template](https://github.com/nix-community/nur-packages-template)（Copyright (c) 2018 Francesco Gazzetta）。