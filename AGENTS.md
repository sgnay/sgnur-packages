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
│   ├── sunloginclient/        # 向日葵远程控制客户端 (AweSun)
│   │   └── default.nix
│   ├── velotype/              # Velotype Markdown 编辑器
│   └── goose-desktop/         # Goose Desktop AI Agent
├── nixos-modules/
│   ├── default.nix            # NixOS 模块集合
│   ├── univpn.nix             # UniVPN NixOS 模块（使用 pkgs.univpn）
│   └── sunloginclient.nix     # 向日葵远程控制 NixOS 模块
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

### 3. 向日葵远程控制客户端 (`pkgs/sunloginclient`)

- **版本**: `16.5.0.30560` (AweSun / Sunlogin Client)
- **描述**: 专有远程控制软件 (Sunlogin)
- **构建方案 (混合打包架构)**:
  - **GUI 启动器 (`/usr/local/awesun/awesun`) 保持原始**: 守护进程会校验 GUI 进程的二进制完整性与哈希签名（通过 `/proc/$PID/exe`）。如果使用 `autoPatchelf` 修改了 ELF 头部或剥离了 `strip`，守护进程将验证失败并不予响应，导致 GUI 卡在“正在连接服务器”。因此，此二进制保留 unmodified，并通过系统级的 `nix-ld` 配合 `NIX_LD_LIBRARY_PATH` 运行。
  - **后台服务二进制 (`awesun_daemon` 等) 进行 `patchelf`**: 由于守护进程启动后台子进程时会清理环境变量，这会导致 `NIX_LD_LIBRARY_PATH` 丢失而无法调用 `nix-ld`（报库缺失错误如 `libgobject`）。故在安装时使用 `patchelf` 显式写入 RPATH 依赖到二进制中，使其能在 Systemd 无环境变量的干净沙箱中独立运行。
- **依赖列表**: `stdenv.cc.cc.lib`, `util-linux.lib`, `gtk3`, `glib`, `cairo`, `pango`, `atk`, `gdk-pixbuf`, `libnotify`, `libepoxy`, `libappindicator-gtk3`, `webkitgtk_4_1`, `zlib`, `dbus`, `libdrm`, `libxkbcommon`, `libX11`, `libXext`, `libXfixes`, `libXrandr`, `libXrender`, `libXinerama`, `libXcursor`, `libXi`, `libXtst`, `libICE`, `libSM`, `libxcb`, `alsa-lib`, `nss`, `nspr`, `fontconfig`, `freetype`
- **注册**: `default.nix` → `pkgs.callPackage ./pkgs/sunloginclient { }`
- **NixOS 模块**: `nixos-modules/sunloginclient.nix` (提供 `services.sunloginclient` 选项，配置 `programs.nix-ld.libraries` 确保环境就绪)

### 4. Velotype 包 (`pkgs/velotype`)

- **版本**: `0.7.0`
- **描述**: [Velotype](https://github.com/manyougz/velotype) — 基于 Rust + GPUI 的原生的 Markdown 编辑器，支持所见即所得 (WYSIWYG) 与源码编辑模式
- **构建方式**:
  - `rustPlatform.buildRustPackage`
  - 使用 `makeWrapper` 硬编码动态链接库与 `XDG_DATA_DIRS`，适配 Linux / Wayland 环境
  - 安装 `.desktop` 桌面入口文件及多分辨率图标
- **注册**: `default.nix` → `pkgs.callPackage ./pkgs/velotype { }`

### 5. CI 流水线 (`.github/workflows/build.yml`)

- **触发器**: PR、push 到 main/master、每日定时（02:51）、手动触发
- **矩阵**: `nixpkgs-unstable`, `nixos-unstable`, `nixos-26.05`
- **nurRepo**: `sgnur-packages`
- **cachix**: 未配置（默认跳过）

## 使用方式

```bash
# 通过 Flake 运行 UniVPN
nix run github:sgnay/sgnur-packages#univpn

# 通过 Flake 运行 Sunlogin (AweSun)
nix run github:sgnay/sgnur-packages#sunloginclient

# 通过 Flake 运行 Velotype
nix run github:sgnay/sgnur-packages#velotype

# 通过 NixOS 模块启用 UniVPN
# configuration.nix:
{
  imports = [ inputs.sgnur-packages.nixosModules.univpn ];
  services.univpn.enable = true;
}

# 通过 NixOS 模块启用 Sunlogin
# configuration.nix:
{
  imports = [ inputs.sgnur-packages.nixosModules.sunloginclient ];
  services.sunloginclient.enable = true;
}

# 本地构建
nix build .#velotype
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
| 打包 sunloginclient | ✅ | 向日葵远程控制客户端 (AweSun)，版本 16.5.0 |
| sunloginclient 混合打包 | ✅ | 后台守护进程 patchelf + 客户端 nix-ld，绕过完整性校验并解决 Systemd 变量清理问题 |
| sunloginclient 服务模块 | ✅ | 一键开启 `services.sunloginclient`，配置全局 nix-ld 依赖支持 |
| 宿主机密钥安全 | ✅ | 将 plaintext 敏感配置 secrets.nix 替换为 sops-nix 密钥密文管理，使用机器 SSH Host Key 动态解密 |
| 打包 velotype | ✅ | Velotype — 基于 Rust + GPUI 的 Markdown 编辑器（版本 0.7.0） |
| 打包 goose-desktop | ✅ | Goose Desktop — 开源 AI Agent 桌面图形应用（版本 1.45.0） |

## 后续建议

| 项目 | 优先级 | 说明 |
|---|---|---|
| 配置 Cachix 缓存 | 低 | 如需加速 CI，创建 Cachix 账号并在 GitHub Secrets 中设置密钥 |
| 补充 `lib/` 函数 | 低 | 当前为空，有通用 Nix 函数时可放入 |
| 补充 `overlays/` | 低 | 当前为空，有额外 overlay 时可放入 |
| sunloginclient 版本更新 | 持续 | 官方升级时及时跟进 Deb 地址与 SHA256 校验码 |

## GUI 应用打包与 Launcher 兼容性指南 (Desktop Launcher Packaging Rules)

### 核心原则
在为 NixOS / Wayland (Niri) / Home Manager 打包图形化应用（如 Tauri、GPUI、GTK4、Qt）时，**绝不能使用 `nix-shell` 或脚本进行运行时动态加载**。桌面 Launcher（如 Niri Launcher / fuzzel / rofi）会在非交互无终端的环境下直接调用 `.desktop` 中的 `Exec` 命令，`nix-shell` 会在此环境下挂起或退出。

### 标准打包规范
1. **`makeWrapper` 依赖硬编码**：使用 `makeWrapper` 显式写入 `LD_LIBRARY_PATH`（如 `fontconfig`, `freetype`, `libxkbcommon`, `wayland`, `vulkan-loader`, `libGL`, `alsa-lib`, `dbus`, `openssl`, `udev`, `stdenv.cc.cc.lib` 等）。
2. **`XDG_DATA_DIRS` 自动注入**：必须前缀包含 `${pkgs.fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}`，防止 GUI 应用因找不到 Schema 或图标在后台静默崩溃。
3. **Home Manager 自动化 Symlink**：将包包含在 Home Manager 的 `home.packages` 中，会自动生成 `~/.nix-profile/share/applications/*.desktop` 和 `~/.nix-profile/bin/*` 软链接，桌面 Launcher 会自动无缝索引。
## Agent 踩坑记录

### 禁止操作
- **永远不要执行 `git push`**。用户已明确要求，commit 后由用户自行推送。
- **构建使用现代化 `nix build` CLI**（如 `nix build .#<pkg>`），尽量不要再使用 `nix-build`。用户已明确要求（2026-09-24）。

### 版本更新常见错误

#### 1. `fetchurl` / `fetchFromGitHub` 哈希更新
当上游版本更新后，tarball/deb 内容变化导致 hash 不匹配。

**症状**：
```
error: hash mismatch in fixed-output derivation ...
         specified: sha256-XXXX...
            got:    sha256-YYYY...
```

**正确做法**：
1. 直接让 nix build 报错，从输出中读取 `got:` 行获取新哈希
2. 不要手动用 `nix-prefetch-url` 计算（它返回的是 tarball 哈希，而 `fetchFromGitHub` 需要 NAR 哈希，两者不同）
3. 用 `got:` 的值替换 `sha256` 字段

#### 2. `fetchPnpmDeps` 的 `fetcherVersion` 与 pnpm 版本绑定
Nixpkgs 升级 pnpm 到 11.x 后，旧版 `fetcherVersion = 3` 不再兼容。

**症状**：
```
error: fetchPnpmDeps `fetcherVersion = 3` is no longer supported for `pnpm_11`.
       Please upgrade to the latest...
```

**正确做法**：
- 将 `fetcherVersion = 3` 改为 `fetcherVersion = 4`
- 同时更新 `hash`（再次让 nix build 报错，取 `got:` 值）
- **不要** 使用 `fetcherVersion = 5`（当前 nixpkgs 尚未支持）

#### 3. `cargoLock.lockFile` 需要与上游版本同步
升级 Rust crate 包时，`Cargo.lock` 文件内容也会变化，旧的本地 `Cargo.lock` 与新源码不匹配。

**症状**：
```
ERROR: cargoHash or cargoSha256 is out of date
       Cargo.lock is not the same in /build/cargo-vendor-dir
```

**正确做法**：
1. 从上游 tag 下载新的 `Cargo.lock`（如 `https://raw.githubusercontent.com/.../v${version}/src-tauri/Cargo.lock`）
2. 覆盖本地的 `Cargo.lock`
3. 再构建获取正确的 `cargoHash`

#### 4. 多包同时更新时的顺序
更新多个包时，建议：
1. 先逐个单独构建验证
2. 确认每个包构建成功后再统一提交
3. 不要一次性修改所有包的版本号而不验证

#### 5. Fcitx5 addon 打包（deb 重打包）

**症状**：addon `ldd` 全部解析，但设置程序静默失败 / 候选窗字体异常。

**原因**：`fontconfig`、`dbus-1`、`libxkbcommon` 是 `dlopen` 依赖，不在 `DT_NEEDED` 里；`autoPatchelfHook` 不会自动补齐。

**正确做法**：
- 把这些库放进 `runtimeDependencies`（会写入 RPATH），而不是只放 `buildInputs`
- **必须用 `lib.getLib`**：`fontconfig` / `dbus` 的默认输出不含 `lib/`，直接传包名会让 RPATH 指向不存在的目录，dlopen 依然失败（症状：设置程序空 UI、候选窗无字）
- 用 `patchelf --print-rpath` 确认目录存在，再用 `strace -f -e trace=openat` 确认 `libfontconfig.so.1` 真正被打开

#### 6. Fcitx5 addon 的目录约定

- addon 描述文件：`$out/share/fcitx5/addon/<name>.conf`
- 输入法描述：`$out/share/fcitx5/inputmethod/<name>.conf`
- 共享库：`$out/lib/fcitx5/lib<name>.so`（`Library=lib<name>` 对应文件名）
- `FCITX_ADDON_DIRS` 指向**库目录**；`XDG_DATA_DIRS` 指向 `share`（fcitx5 会自动追加 `/fcitx5`）
- `OnDemand=True` 的 addon **不会在启动时 dlopen**；无窗口焦点时 `fcitx5-remote -s <name>` 也不会触发加载。离线只能验证 conf 解析与路径合并，实际打字必须在图形会话内验证

### 哈希获取速查表

| 场景 | 命令 / 方法 |
|---|---|
| `fetchurl`（tar.gz / .deb）哈希 | 运行 `nix build`，从 `got: sha256-...` 取新值 |
| `fetchFromGitHub` 源哈希 | 运行 `nix build`，从 `got: sha256-...` 取新值 |
| `fetchPnpmDeps` 哈希 | 更新 `fetcherVersion` 后运行 `nix build`，从 `got: sha256-...` 取新值 |
| `cargoHash` | 运行 `nix build`，从 `got: sha256-...` 取新值 |
| `nix-prefetch-url` | 返回 base32 NAR 哈希，**不适用于** `fetchFromGitHub` 的 SRI 格式 |
| 官方 `.sha256` 文件（hex）转 SRI | `nix hash convert --hash-algo sha256 --to sri <hex>` |
