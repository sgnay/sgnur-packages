{ lib
, pkgs
, stdenv
, fetchFromGitHub
, rustPlatform
, pnpm
, fetchPnpmDeps
, pnpmConfigHook
, nodejs
, makeWrapper
}:

let
  version = "1.1.13";
  pname = "nyaterm";

  # No tags in the repo, use the latest commit on main
  src = fetchFromGitHub {
    owner = "nyakang";
    repo = "nyaterm";
    rev = "2f0059d69058ad75b12c7a64a65c97528d1cfa49";
    hash = "sha256-9bbZFYZH0J0vqLYs/H2HaYGlCS2ItG/YVj6oiR+/qM4=";
  };

  # Pre-fetched pnpm dependencies
  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    pnpm = pnpm;
    fetcherVersion = 3;
    hash = "sha256-DddIM6y1vRvO845QXPPxQk6RLkV7Ey8KJ31gb0EfO2M=";
  };
in
rustPlatform.buildRustPackage {
  pname = pname;
  inherit version src;

  cargoRoot = "src-tauri";
  buildAndTestSubdir = "src-tauri";
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  inherit pnpmDeps;

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
    makeWrapper
    # Tauri 2 system dependencies for build
    pkgs.pkg-config
  ];

  buildInputs = [
    # Tauri 2 Linux dependencies
    pkgs.webkitgtk_4_1
    pkgs.libsoup_3
    pkgs.gtk3
    pkgs.glib
    pkgs.cairo
    pkgs.gdk-pixbuf
    pkgs.pango
    pkgs.atk
    pkgs.gobject-introspection
    pkgs.libxcb
    pkgs.libx11
    pkgs.libxkbcommon
    pkgs.freetype
    pkgs.fontconfig
    pkgs.dbus
    pkgs.openssl
    pkgs.zlib
    pkgs.brotli
    pkgs.libappindicator-gtk3
    pkgs.librsvg
    pkgs.udev
    pkgs.gsettings-desktop-schemas
  ];

  # Skip tests — they fail in sandbox due to concurrent DB access
  doCheck = false;

  # Patch Cargo.toml to enable custom-protocol feature, which makes
  # the app use embedded frontend assets instead of dev server URL
  postPatch = ''
    substituteInPlace src-tauri/Cargo.toml \
      --replace-fail 'tauri = { version = "2", features = [' 'tauri = { version = "2", features = ["custom-protocol", '
  '';

  # Build frontend (pnpm) then Rust backend
  # pnpmConfigHook already ran pnpm install in configurePhase,
  # so node_modules is ready at the source root.
  preBuild = ''
    pnpm build
  '';

  # buildRustPackage runs cargo build which produces the binary in
  # target/release/nyaterm (relative to cargoRoot, i.e. src-tauri/).
  # The binary name is defined by Cargo.toml [package].name.
  postInstall = ''
    # The binary is already installed by cargoInstallHook.
    # Wrap it with LD_LIBRARY_PATH for runtime dependencies not auto-detected.
    wrapProgram $out/bin/nyaterm \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (with pkgs; [
        webkitgtk_4_1
        libsoup_3
        gtk3
        glib
        cairo
        gdk-pixbuf
        pango
        atk
        libxcb
        libx11
        libxkbcommon
        freetype
        fontconfig
        dbus.lib
        openssl
        libappindicator-gtk3
        librsvg
        udev
      ])} \
      --set-default GDK_BACKEND x11 \
      --prefix XDG_DATA_DIRS : ${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}

    # Install icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${src}/src-tauri/icons/icon.png $out/share/icons/hicolor/256x256/apps/nyaterm.png

    # Install desktop entry
    mkdir -p $out/share/applications
    cp ${./nyaterm.desktop.in} $out/share/applications/nyaterm.desktop
    substituteInPlace $out/share/applications/nyaterm.desktop \
      --replace '@out@' "$out"
  '';

  meta = with lib; {
    description = "A modern remote terminal workspace built with Tauri, React, and Rust (SSH, local shells, Telnet, Serial, SFTP)";
    longDescription = ''
      NyaTerm is a desktop client for SSH-centric operations and mixed terminal
      workflows. It combines a React + Tauri interface with a Rust backend so
      you can manage remote hosts, local shells, file transfers, authentication,
      network tooling, AI-assisted terminal actions, session import/export,
      diagnostics, and encrypted sync/backup from one workspace.
    '';
    homepage = "https://nyaterm.app";
    changelog = "https://github.com/nyakang/nyaterm/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ sgnay ];
    platforms = platforms.linux;
    mainProgram = "nyaterm";
  };
}