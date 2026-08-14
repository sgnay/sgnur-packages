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
  ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar --no-same-permissions --no-same-owner -x
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/share/applications $out/share/icons/hicolor
    cp -r usr/share/icons $out/share/
    cp -r usr/lib/reasonix $out/lib/

    # 清理 deb 包中原本指向 reasonix-launcher 的 .desktop 文件
    rm -rf $out/share/applications/*

    # 封装可执行文件并注入库路径、XDG 资源环境
    # reasonix-launcher 是实际启动器，reasonix-desktop 是主二进制
    makeWrapper $out/lib/reasonix/reasonix-launcher $out/bin/deepseek-reasonix \
      --prefix LD_LIBRARY_PATH : "$out/lib/reasonix:${libPath}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"

    # 复制图标到 512x512 尺寸（Launcher 常用）
    mkdir -p $out/share/icons/hicolor/512x512/apps
    if [ -f $out/share/icons/hicolor/256x256/apps/reasonix-desktop.png ]; then
      cp $out/share/icons/hicolor/256x256/apps/reasonix-desktop.png $out/share/icons/hicolor/512x512/apps/deepseek-reasonix.png
    fi

    # 生成标准的 Desktop 桌面入口文件
    cat <<EOF > $out/share/applications/deepseek-reasonix.desktop
[Desktop Entry]
Type=Application
Name=DeepSeek Reasonix
Comment=AI reasoning engine desktop application
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
