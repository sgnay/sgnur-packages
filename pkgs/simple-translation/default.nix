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
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "sgnay";
    repo = "simple-translation";
    rev = "de8195435f1ed80d8bc2aaaeced85e4f639303d3";
    hash = "sha256-vwDPw1dsLjMUfEfE+2rBXOc9QeKl8mzra0h1ViEriu0=";
  };

  cargoHash = "sha256-v80lp6KmYQrbRZKlW92KHgKzTznkJbzLeiEer8iGnnk=";

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
  ];

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
      --prefix LD_LIBRARY_PATH : "${libPath}"
  '';

  meta = with lib; {
    description = "A simple Linux desktop translator written in Rust and egui";
    homepage = "https://github.com/sgnay/simple-translation";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "simple-translation";
  };
}
