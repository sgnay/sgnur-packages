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
  python3,
  fontconfig,
  freetype,
  pkgs,
}:

let
  pname = "goose-desktop";
  version = "1.45.0";

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
    url = "https://github.com/aaif-goose/goose/releases/download/v${version}/goose_${version}_amd64.deb";
    sha256 = "009d2bsx4a5384b6280ih4s1hvzkpdmn7cv4zi8b1phgpkx6p20b";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
    python3
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

    mkdir -p $out/bin $out/lib $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps
    cp -r usr/share/* $out/share/ 2>/dev/null || true
    cp -r usr/lib/goose $out/lib/

    # 清理 deb 包中原本不可用/空的 .desktop 占位文件
    rm -rf $out/share/applications/*

    # 修复 Electron 主窗口初始隐藏问题，强行开启启动即显示窗口 (show: true)
    python3 -c '
with open("'$out'/lib/goose/resources/app.asar", "rb") as f:
    d = f.read()
d = d.replace(b"BrowserWindow({show:!1", b"BrowserWindow({show:!0")
with open("'$out'/lib/goose/resources/app.asar", "wb") as f:
    f.write(d)
'

    # 建立 ANGLE 渲染所需的 EGL 与 GLES 共享动态库符号链接
    ln -s libEGL.so $out/lib/goose/libEGL.so.1 || true
    ln -s libGLESv2.so $out/lib/goose/libGLESv2.so.2 || true

    # 封装可执行文件并注入库路径、XDG 资源环境及 Electron 必要的沙盒与 GPU 参数
    makeWrapper $out/lib/goose/Goose $out/bin/goose-desktop \
      --prefix LD_LIBRARY_PATH : "$out/lib/goose:${libPath}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}" \
      --add-flags "--no-sandbox" \
      --add-flags "--disable-gpu-sandbox" \
      --add-flags "--disable-gpu"

    # 复制并配置图标
    if [ -f $out/share/pixmaps/goose.png ]; then
      cp $out/share/pixmaps/goose.png $out/share/icons/hicolor/512x512/apps/goose-desktop.png
      cp $out/share/pixmaps/goose.png $out/share/icons/hicolor/512x512/apps/goose.png
    fi

    # 生成标准的 Desktop 桌面入口文件
    cat <<EOF > $out/share/applications/goose-desktop.desktop
[Desktop Entry]
Name=Goose Desktop
Comment=Open source AI agent application
Exec=$out/bin/goose-desktop %U
Icon=goose-desktop
Terminal=false
Type=Application
Categories=Development;Utility;
Keywords=goose;ai;agent;llm;chat;
EOF

    cat <<EOF > $out/share/applications/goose.desktop
[Desktop Entry]
Name=Goose Desktop
Comment=Open source AI agent application
Exec=$out/bin/goose-desktop %U
Icon=goose
Terminal=false
Type=Application
Categories=Development;Utility;
Keywords=goose;ai;agent;llm;chat;
EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Goose Desktop — Open source AI agent application";
    homepage = "https://github.com/aaif-goose/goose";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose-desktop";
  };
}
