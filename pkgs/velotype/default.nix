{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, makeWrapper
, fontconfig
, freetype
, libxkbcommon
, wayland
, vulkan-loader
, libGL
, alsa-lib
, dbus
, openssl
, udev
, stdenv
, gtk3
, libx11
, libxcursor
, libxi
, libxrandr
, libxcb
}:

rustPlatform.buildRustPackage rec {
  pname = "velotype";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "manyougz";
    repo = "velotype";
    rev = "v${version}";
    hash = "sha256-wGA2t4dBjEc9jAGnGdUL/0WOFdZuOPR5envcORoDx+o=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    fontconfig
    freetype
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    vulkan-loader
    libGL
    alsa-lib
    dbus
    openssl
    udev
  ];

  doCheck = false;

  postInstall = ''
    install -Dm644 resources/linux/com.manyougz.Velotype.desktop -t $out/share/applications/
    install -Dm644 resources/linux/icons/hicolor/256x256/apps/com.manyougz.Velotype.png -t $out/share/icons/hicolor/256x256/apps/
    install -Dm644 resources/linux/icons/hicolor/512x512/apps/com.manyougz.Velotype.png -t $out/share/icons/hicolor/512x512/apps/

    wrapProgram $out/bin/velotype \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        fontconfig
        freetype
        libxkbcommon
        wayland
        libx11
        libxcursor
        libxi
        libxrandr
        libxcb
        vulkan-loader
        libGL
        alsa-lib
        dbus
        openssl
        udev
        stdenv.cc.cc.lib
      ]}" \
      --prefix XDG_DATA_DIRS : "${fontconfig}/share:${gtk3}/share/gsettings-schemas/gtk+3-${gtk3.version}"
  '';

  meta = with lib; {
    description = "Native Markdown editor built with Rust and GPUI with WYSIWYG and source editing modes";
    homepage = "https://github.com/manyougz/velotype";
    license = licenses.asl20;
    mainProgram = "velotype";
    platforms = platforms.linux;
  };
}
