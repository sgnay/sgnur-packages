{ lib
, pkgs
, stdenv
, fetchzip
, fontconfig
, freetype
, libxkbcommon
, libX11
, libxcb
, libXcursor
, libXrandr
, libXi
, libXfixes
, libXrender
, wayland
, vulkan-loader
, libGL
, alsa-lib
, dbus
, openssl
, zlib
, udev
, gst_all_1
, makeWrapper
}:

let
  pname = "oxideterm";
  version = "2.0.14";

  libPath = lib.makeLibraryPath [
    fontconfig
    freetype
    libxkbcommon
    libX11
    libxcb
    libXcursor
    libXrandr
    libXi
    libXfixes
    libXrender
    wayland
    vulkan-loader
    libGL
    alsa-lib
    dbus.lib
    openssl
    zlib
    udev
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    url = "https://github.com/AnalyseDeCircuit/oxideterm/releases/download/v${version}/OxideTerm_${version}_linux_x64_portable.tar.gz";
    hash = "sha256-blrHVteBljREznL012fQyZjct1QulvkCv5hU9/kJAyY=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/128x128/apps $out/share/icons/hicolor/64x64/apps $out/share/oxideterm

    # Copy resources & binaries
    cp -r $src/* $out/share/oxideterm/
    cp $src/resources/icons/128x128.png $out/share/icons/hicolor/128x128/apps/oxideterm.png 2>/dev/null || true
    cp $src/resources/icons/64x64.png $out/share/icons/hicolor/64x64/apps/oxideterm.png 2>/dev/null || true

    cp $src/oxideterm-native $out/bin/oxideterm-native
    if [ -f $src/resources/cli-bin/x86_64-unknown-linux-gnu/oxideterm ]; then
      cp $src/resources/cli-bin/x86_64-unknown-linux-gnu/oxideterm $out/bin/oxideterm-cli
    fi

    makeWrapper $out/bin/oxideterm-native $out/bin/oxideterm \
      --prefix LD_LIBRARY_PATH : "${libPath}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"

    if [ -f $out/bin/oxideterm-cli ]; then
      makeWrapper $out/bin/oxideterm-cli $out/bin/oxideterm-cli-wrapper \
        --prefix LD_LIBRARY_PATH : "${libPath}"
    fi

    cat <<EOF > $out/share/applications/oxideterm.desktop
[Desktop Entry]
Name=OxideTerm
Comment=AI-native workspace for local shells and remote machines
Exec=$out/bin/oxideterm %U
Icon=oxideterm
Terminal=false
Type=Application
Categories=Development;System;TerminalEmulator;
Keywords=ssh;terminal;ai;rdp;sftp;
EOF
  '';

  meta = with lib; {
    description = "AI-native workspace for local shells and remote machines";
    homepage = "https://github.com/AnalyseDeCircuit/oxideterm";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "oxideterm";
  };
}
