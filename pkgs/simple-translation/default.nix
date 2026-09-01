{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  pkg-config,
  wayland,
  libxkbcommon,
  libGL,
  libglvnd,
  libX11,
  libXcursor,
  libXrandr,
  libXi,
  openssl,
  dbus,
  nss,
  cacert,
}:
let
  libPath = lib.makeLibraryPath [
    wayland
    libxkbcommon
    libGL
    libglvnd
    libX11
    libXcursor
    libXrandr
    libXi
    stdenv.cc.cc.lib
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "simple-translation";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "sgnay";
    repo = "simple-translation";
    rev = "b4eceee3593a1d37e1cdf6050528084380fe3d39";
    hash = "sha256-aaS+iHd98TCgSwgxz9/tbvtrBOyMd6pVXkoLMJOZ5cM=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    wayland
    libxkbcommon
    libGL
    libglvnd
    libX11
    libXcursor
    libXrandr
    libXi
    openssl
    dbus
    nss
  ];

  doCheck = false;

  postInstall = ''

    mkdir -p $out/share/applications

    cat <<EOF > $out/share/applications/simple-translation.desktop
[Desktop Entry]
Name=Simple Translation
Name[zh_CN]=简单翻译
Comment=A simple Linux desktop translator written in Rust and egui
Exec=$out/bin/simple-translation %U
Terminal=false
Type=Application
Categories=Utility;Development;
Keywords=translation;translator;dictionary;
EOF

    wrapProgram $out/bin/simple-translation \
      --prefix LD_LIBRARY_PATH : "${libPath}" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  meta = with lib; {
    description = "A simple Linux desktop translator written in Rust and egui";
    homepage = "https://github.com/sgnay/simple-translation";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "simple-translation";
  };
}
