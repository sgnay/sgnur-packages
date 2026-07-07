{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.univpn;

  # ── 使用 pkgs 中的 univpn 包（由 default.nix 加载） ──
  univpn = pkgs.univpn;

  # ── Nixpkgs Qt5 路径 ────────────────────────────────
  qt5lib = pkgs.qt5.qtbase.out;
  qt5svg = pkgs.qt5.qtsvg.out;

  # ── 系统库路径（nixpkgs Qt5 + xcb/X11 系统库） ──────
  libPath = lib.concatStringsSep ":" [
    "${qt5lib}/lib"
    "${qt5svg}/lib"
    "${pkgs.libxcb}/lib"
    "${pkgs.libx11}/lib"
    "${pkgs.libxcb-util}/lib"
    "${pkgs.libxcb-image}/lib"
    "${pkgs.libxcb-keysyms}/lib"
    "${pkgs.libxcb-render-util}/lib"
    "${pkgs.libxcb-wm}/lib"
    "${pkgs.libxkbcommon}/lib"
    "${pkgs.fontconfig.lib}/lib"
    "${pkgs.freetype}/lib"
    "${pkgs.libglvnd}/lib"
    "${pkgs.stdenv.cc.cc.lib}/lib"
    "${pkgs.zstd.out}/lib"
  ];

  # ── 启动 wrapper（以用户身份运行） ──────────────────
  wrapper = pkgs.writeShellApplication {
    name = "univpn";
    text = ''
      export LD_LIBRARY_PATH="${libPath}$''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
      export QT_PLUGIN_PATH="${qt5lib}/plugins"
      cd /usr/local/UniVPN
      exec /usr/local/UniVPN/UniVPN "$@"
    '';
  };

  # ── 停止/重启命令 ────────────────────────────────────
  stopScript = pkgs.writeShellScriptBin "univpn-stop" ''
    echo "Stopping UniVPN..."
    sudo pkill -9 -f "UniVPN" 2>/dev/null
    sudo pkill -9 -f "UniVPNPromoteService" 2>/dev/null
    sudo pkill -9 -f "UniVPNCS" 2>/dev/null
    sudo rm -f /tmp/29191 /tmp/29192 2>/dev/null
    echo "UniVPN stopped."
  '';

  restartScript = pkgs.writeShellScriptBin "univpn-restart" ''
    univpn-stop
    sleep 2
    exec univpn
  '';

  # ── 桌面入口 ──────────────────────────────────────────
  desktopEntry = pkgs.runCommand "univpn.desktop" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/univpn.desktop <<'EOF'
[Desktop Entry]
Name=UniVPN
Name[zh_CN]=UniVPN
Comment=Leagsoft UniVPN Client
Exec=/run/current-system/sw/bin/univpn
Icon=${univpn}/image/ICON.ico
Path=/usr/local/UniVPN
Terminal=false
Type=Application
Categories=Network;
StartupNotify=true
DBusActivatable=false
EOF
  '';

in
{
  options.services.univpn = {
    enable = mkEnableOption "Leagsoft UniVPN client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ univpn wrapper desktopEntry stopScript restartScript ];
    system.activationScripts.univpn = stringAfter [ "binsh" "users" ] ''
      mkdir -p /usr/local/UniVPN
      cp -r ${univpn}/* /usr/local/UniVPN/
      chmod -R u+w /usr/local/UniVPN/
      mkdir -p /usr/local/UniVPN/log /usr/local/UniVPN/certificate
      chmod 777 /usr/local/UniVPN/log
      chmod 755 /usr/local/UniVPN/certificate
      chmod 666 /usr/local/UniVPN/sysconfig.ini 2>/dev/null || true
      chmod u+s /usr/local/UniVPN/serviceclient/UniVPNCS
      chmod u+s /usr/local/UniVPN/promote/UniVPNPromoteService
      chmod u+s /usr/local/UniVPN/UniVPNUpdate
      rm -f /usr/local/UniVPN/lib/libQt5*.so.5
      rm -f /usr/local/UniVPN/lib/libxcb-xinerama*
      rm -f /usr/local/UniVPN/lib/libxcb-xinput*
    '';
    systemd.tmpfiles.rules = [ "L+ /usr/bin/pgrep - - - - ${pkgs.procps}/bin/pgrep" ];
  };
}