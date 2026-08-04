# pkgs/pot-translation/default.nix — 原生打包 pot-translation (免 bwrap 沙盒)
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  patchelf,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  libsoup_3,
  openssl,
  alsa-lib,
  libayatana-appindicator,
  libappindicator-gtk3,
  xdotool,
  libx11,
  libxext,
  libxrender,
  libxi,
  libxrandr,
  libxcursor,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxtst,
}:

stdenv.mkDerivation rec {
  pname = "pot-translation";
  version = "3.0.7";

  src = fetchurl {
    url = "https://github.com/pot-app/pot-desktop/releases/download/${version}/pot_${version}_amd64.deb";
    sha256 = "1dxj26lpdl3c3a7zphxchy2v2hswbvsz6a0f7h8wvvvrl0idd7kf";
  };

  nativeBuildInputs = [
    dpkg
    patchelf
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libsoup_3
    openssl
    alsa-lib
    libayatana-appindicator
    libappindicator-gtk3
    xdotool
    libx11
    libxext
    libxrender
    libxi
    libxrandr
    libxcursor
    libxcomposite
    libxdamage
    libxfixes
    libxtst
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
    patchelf --replace-needed libwebkit2gtk-4.0.so.37 libwebkit2gtk-4.1.so.0 usr/bin/pot || true
    patchelf --replace-needed libsoup-2.4.so.1 libsoup-3.0.so.0 usr/bin/pot || true
    patchelf --replace-needed libjavascriptcoregtk-4.0.so.18 libjavascriptcoregtk-4.1.so.0 usr/bin/pot || true
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp -r usr/share/* $out/share/
    cp usr/bin/pot $out/bin/pot

    # 修复 desktop 文件中的 Exec 路径与图标名
    substituteInPlace $out/share/applications/pot.desktop \
      --replace-fail "Exec=pot" "Exec=$out/bin/pot"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libayatana-appindicator libappindicator-gtk3 webkitgtk_4_1 gtk3 ]}"
      --set WEBKIT_DISABLE_DMABUF_RENDERER "1"
      --set WEBKIT_DISABLE_COMPOSITING_MODE "1"
    )
  '';

  meta = with lib; {
    description = "A cross-platform software for text translation and OCR";
    homepage = "https://pot-app.com";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "pot";
  };
}
