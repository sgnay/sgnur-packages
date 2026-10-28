{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libglvnd,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxtst,
  mesa,
  nspr,
  nss,
  pango,
  udev,
  vulkan-loader,
  zlib,
}:

let
  pname = "deepseek-reasonix";
  version = "1.39.10";

  runtimeLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libglvnd
    libnotify
    libsecret
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxrender
    libxtst
    mesa
    nspr
    nss
    pango
    udev
    vulkan-loader
    zlib
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/esengine/DeepSeek-Reasonix/releases/download/desktop-v${version}/Reasonix-linux-amd64.deb";
    hash = "sha256-7PtJyfgdILq4WuvJRR8+4ij0Azak6K0YQHLgJ9XDBPY=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar --no-same-permissions --no-same-owner -x
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/reasonix $out/share/applications

    # reasonix-desktop resolves the Electron shell (app/Reasonix) next to its
    # own executable, so the Go host and the Chromium bundle stay together.
    install -Dm755 usr/bin/reasonix-desktop $out/lib/reasonix/reasonix-desktop
    install -Dm755 usr/lib/reasonix/reasonix-update-helper $out/lib/reasonix/reasonix-update-helper
    cp -r usr/lib/reasonix/app $out/lib/reasonix/app
    chmod -R u+w $out/lib/reasonix/app

    # Electron's setuid sandbox helper cannot keep its 4755 mode inside the
    # store and Chromium refuses to use it otherwise; dropping it makes the
    # shell fall back to the unprivileged user-namespace sandbox.
    rm -f $out/lib/reasonix/app/chrome-sandbox

    cp -r usr/share/icons usr/share/pixmaps usr/share/polkit-1 $out/share/

    makeWrapper $out/lib/reasonix/reasonix-desktop $out/bin/deepseek-reasonix \
      --prefix LD_LIBRARY_PATH : "$out/lib/reasonix:${lib.makeLibraryPath runtimeLibs}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${gtk3}/share/gsettings-schemas/gtk+3-${gtk3.version}"

    cat > $out/share/applications/deepseek-reasonix.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=DeepSeek Reasonix
    Comment=Reasonix desktop — an Electron shell around the Go kernel
    Exec=$out/bin/deepseek-reasonix %U
    Icon=reasonix-desktop
    Categories=Development;Utility;
    Terminal=false
    Keywords=deepseek;reasonix;ai;reasoning;agent;
    StartupWMClass=Reasonix
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
