{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  gtk3,
  glibc,
  stdenvCC ? stdenv.cc.cc.lib,
  openssl,
  zlib,
  dbus,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  expat,
  gdk-pixbuf,
  glib,
  nss,
  nspr,
  pango,
  libxkbcommon,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libXrender,
  libXtst,
  libxcb,
  systemd,
  mesa,
  libGL,
  libglvnd,
  vulkan-loader,
  libnotify,
  libsecret,
  fontconfig,
  freetype,
  webkitgtk_4_1,
  libsoup_3,
  pkgs,
}:

let
  pname = "deepseek-reasonix";
  version = "1.25.1";

  libPath = lib.makeLibraryPath [
    stdenvCC
    glibc
    openssl
    zlib
    dbus
    alsa-lib
    at-spi2-atk
    cairo
    cups
    expat
    gdk-pixbuf
    glib
    gtk3
    nss
    nspr
    pango
    libxkbcommon
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXrender
    libXtst
    libxcb
    systemd
    mesa
    libGL
    libglvnd
    vulkan-loader
    libnotify
    libsecret
    fontconfig
    freetype
    webkitgtk_4_1
    libsoup_3
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/esengine/DeepSeek-Reasonix/releases/download/desktop-v${version}/Reasonix-linux-amd64.deb";
    sha256 = "1ldzm4j5j1y44hmbpbcnng52chbg3pzj8ka9wdnfs5q5svan5ags";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];



  buildInputs = [
    gtk3
    stdenvCC
    openssl
    zlib
    dbus
    alsa-lib
    at-spi2-atk
    cairo
    cups
    expat
    gdk-pixbuf
    glib
    nss
    nspr
    pango
    libxkbcommon
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXrender
    libXtst
    libxcb
    systemd
    mesa
    libGL
    libglvnd
    vulkan-loader
    libnotify
    libsecret
    fontconfig
    freetype
    webkitgtk_4_1
    libsoup_3
  ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar --no-same-permissions --no-same-owner -x
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/share/applications $out/share/icons/hicolor $out/share/pixmaps
    
    # 复制二进制文件到 out/lib/reasonix
    mkdir -p $out/lib/reasonix
    cp usr/bin/reasonix-desktop $out/lib/reasonix/
    cp usr/bin/reasonix-update-helper $out/lib/reasonix/ 2>/dev/null || true
    
    # 复制图标资源
    cp -r usr/share/icons $out/share/
    cp usr/share/pixmaps/reasonix-desktop.png $out/share/pixmaps/ 2>/dev/null || true
    
    # 复制 polkit 策略文件
    cp -r usr/share/polkit-1 $out/share/ 2>/dev/null || true

    # 清理 deb 包中原本指向 reasonix-launcher 的 .desktop 文件
    rm -rf $out/share/applications/*

    # 封装 reasonix-desktop 主二进制并注入库路径、XDG 资源环境
    # reasonix-desktop 是动态链接的 GUI 主程序
    makeWrapper $out/lib/reasonix/reasonix-desktop $out/bin/deepseek-reasonix \
      --prefix LD_LIBRARY_PATH : "$out/lib/reasonix:${libPath}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"

    # 复制图标到 512x512 尺寸（Launcher 常用）
    mkdir -p $out/share/icons/hicolor/512x512/apps
    if [ -f $out/share/icons/hicolor/512x512/apps/reasonix-desktop.png ]; then
      cp $out/share/icons/hicolor/512x512/apps/reasonix-desktop.png $out/share/icons/hicolor/512x512/apps/deepseek-reasonix.png
    fi

    # 生成标准的 Desktop 桌面入口文件
    cat <<EOF > $out/share/applications/deepseek-reasonix.desktop
[Desktop Entry]
Type=Application
Name=DeepSeek Reasonix
Comment=Reasonix desktop — a Wails shell around the Go kernel
Exec=$out/bin/deepseek-reasonix %U
Icon=deepseek-reasonix
Terminal=false
Categories=Development;Utility;
Keywords=deepseek;reasonix;ai;reasoning;agent;
StartupWMClass=reasonix-desktop
EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "DeepSeek Reasonix — AI reasoning engine desktop application";
    homepage = "https://github.com/esengine/deepseek-reasonix";
    license = licenses.unfree; # Proprietary software
    platforms = [ "x86_64-linux" ];
    mainProgram = "deepseek-reasonix";
  };
}
