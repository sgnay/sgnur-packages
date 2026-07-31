{ lib
, pkgs
, stdenv
, fetchFromGitHub
, pkg-config
, cmake
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
, sqlite
, udev
, gst_all_1
, makeWrapper
, binaryDir ? /home/sgnay/oxideterm/target/release
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

  src = fetchFromGitHub {
    owner = "AnalyseDeCircuit";
    repo = "oxideterm";
    rev = "fc3dd77b2a6ff596f7e783800a53e72f942101c0";
    hash = "sha256-dUALHeFkJIEKPhXLYelkhha2+9EoB+yLPCX3nnf05Fg=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/128x128/apps $out/share/icons/hicolor/64x64/apps

    cp ${binaryDir}/oxideterm-native $out/bin/oxideterm-native
    cp ${binaryDir}/oxideterm $out/bin/oxideterm-cli

    cp $src/crates/oxideterm-gpui-app/resources/icons/128x128.png $out/share/icons/hicolor/128x128/apps/oxideterm.png
    cp $src/crates/oxideterm-gpui-app/resources/icons/64x64.png $out/share/icons/hicolor/64x64/apps/oxideterm.png

    makeWrapper $out/bin/oxideterm-native $out/bin/oxideterm \
      --prefix LD_LIBRARY_PATH : "${libPath}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"

    makeWrapper $out/bin/oxideterm-cli $out/bin/oxideterm-cli-wrapper \
      --prefix LD_LIBRARY_PATH : "${libPath}"

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
