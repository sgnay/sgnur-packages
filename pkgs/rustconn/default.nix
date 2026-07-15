{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, wrapGAppsHook4
, libadwaita
, vte-gtk4
, openssl
, dbus
, zstd
, alsa-lib
, gettext
, glib
, gtk4
}:

rustPlatform.buildRustPackage rec {
  pname = "rustconn";
  version = "0.18.8";

  src = fetchFromGitHub {
    owner = "totoshko88";
    repo = "RustConn";
    rev = "v${version}";
    hash = "sha256-GZIMcXehl8ohAvjcGveVp4pcNdcpl/HI8VWtT6UgPVw=";
  };

  cargoHash = "sha256-3wszGV03MAZ4ckbIZ0V91Re1CO2m9vclOCnOYUQdt3w=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    glib # for glib-compile-schemas / msgfmt / etc. if needed
    gettext
  ];

  buildInputs = [
    libadwaita
    vte-gtk4
    openssl
    dbus
    zstd
    alsa-lib
    glib
    gtk4
  ];

  # RustConn is a cargo workspace containing rustconn (GUI) and rustconn-cli (CLI).
  # We want to build both.
  buildAndTestSubdir = ""; # Build at workspace root

  cargoBuildFlags = [
    "-p" "rustconn" "--features" "adw-1-8"
    "-p" "rustconn-cli" "--features" "full"
  ];

  # Since we are building specific workspace packages, cargoTestFlags should also match
  cargoTestFlags = [
    "-p" "rustconn"
    "-p" "rustconn-cli"
  ];

  # Skip tests if they fail in nix sandbox (like many network/GUI apps)
  doCheck = false;

  postInstall = ''
    # Install desktop entry, metainfo, mime types, icons and locales
    # similar to the packaging step in AUR / upstream.
    
    install -Dm644 rustconn/assets/io.github.totoshko88.RustConn.desktop -t $out/share/applications/
    install -Dm644 rustconn/assets/io.github.totoshko88.RustConn.metainfo.xml -t $out/share/metainfo/
    install -Dm644 rustconn/assets/io.github.totoshko88.RustConn-rdp.xml -t $out/share/mime/packages/
    install -Dm644 rustconn/assets/io.github.totoshko88.RustConn-vv.xml -t $out/share/mime/packages/
    
    install -Dm644 rustconn/assets/icons/hicolor/scalable/apps/io.github.totoshko88.RustConn.svg -t $out/share/icons/hicolor/scalable/apps/
    
    for i in 128 256; do
      install -Dm644 rustconn/assets/icons/hicolor/''${i}x''${i}/apps/io.github.totoshko88.RustConn.png -t $out/share/icons/hicolor/''${i}x''${i}/apps/
    done

    # Build and install locales
    for po_file in po/*.po; do
      if [ -f "$po_file" ]; then
        lang=$(basename "$po_file" .po)
        mkdir -p "$out/share/locale/$lang/LC_MESSAGES"
        msgfmt -o "$out/share/locale/$lang/LC_MESSAGES/rustconn.mo" "$po_file"
      fi
    done
  '';

  meta = with lib; {
    description = "Modern connection manager for Linux with GTK4/Wayland-native interface";
    homepage = "https://github.com/totoshko88/RustConn";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
