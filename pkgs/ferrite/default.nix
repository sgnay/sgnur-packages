{ lib
, pkgs
, stdenv
, fetchFromGitHub
, rustPlatform
, makeWrapper
, pkg-config
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
, gtk3
, libx11
, libxcursor
, libxi
, libxrandr
, libxcb
}:

rustPlatform.buildRustPackage rec {
  pname = "ferrite";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "OlaProeis";
    repo = "Ferrite";
    rev = "v${version}";
    hash = "sha256-fo5Bj5he2rFdtdjHrFcnv66IRIyLYOxPiYE0b0Jplas=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    alsa-lib
    fontconfig
    freetype
    dbus
    openssl
    udev
    gtk3
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
  ];

  doCheck = false;

  postInstall = ''
    # Wrap with necessary library paths and XDG_DATA_DIRS
    wrapProgram $out/bin/ferrite \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (with pkgs; [
        wayland
        libxkbcommon
        vulkan-loader
        libGL
        alsa-lib
        fontconfig
        freetype
        dbus.lib
        openssl
        libx11
        libxcursor
        libxi
        libxrandr
        libxcb
        gtk3
      ])} \
      --set XDG_DATA_DIRS ${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}:${pkgs.fontconfig}/share

    # Install desktop entry
    mkdir -p $out/share/applications
    cp ${src}/assets/icons/linux/ferrite.desktop $out/share/applications/ferrite.desktop
    substituteInPlace $out/share/applications/ferrite.desktop \
      --replace '@out@' "$out" \
      --replace '/usr/bin/ferrite' "$out/bin/ferrite"

    # Install icon (256x256)
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${src}/assets/icons/icon_256.png $out/share/icons/hicolor/256x256/apps/ferrite.png
  '';

  meta = with lib; {
    description = "A fast, lightweight text editor for Markdown, JSON, and more";
    homepage = "https://github.com/OlaProeis/Ferrite";
    license = licenses.mit;
    maintainers = [ {
      name = "sgnay";
      github = "sgnay";
    } ];
    platforms = platforms.linux;
    mainProgram = "ferrite";
  };
}