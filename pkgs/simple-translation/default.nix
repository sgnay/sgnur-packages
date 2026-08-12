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
    rev = "54e4cbc622925d4770b6350743ef7326cab0b94a";
    hash = "sha256-42q3+oEEWEjCTOIqN36TEZE45jQVVcUoMKVaMPlLoc8=";
  };

  cargoHash = "sha256-FKS34O38fMkZEplA6FJe8hseKjYTHw78pKGJfw71CB0=";

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
