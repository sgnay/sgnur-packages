{ lib, stdenv, fetchFromGitHub, rustPlatform, makeWrapper, pkg-config
, fontconfig, freetype, libxkbcommon, wayland, vulkan-loader, libGL
, alsa-lib, dbus, openssl, udev, gtk3, libappindicator-gtk3, tesseract
, libx11, libxcursor, libxi, libxrandr, libxcb
}:

let
  libPath = lib.makeLibraryPath [
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    stdenv.cc.cc.lib
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "simple-ocr";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "sgnay";
    repo = "simple-ocr";
    rev = "v${version}";
    hash = "sha256-biPU9s9IQL6jPD5nk+MdQlz8n6YjY+oxMaBwwnCLMTU=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [ pkg-config makeWrapper ];

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
    gtk3
    libappindicator-gtk3
    tesseract
  ];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/applications

    cat <<EOF > $out/share/applications/simple-ocr.desktop
[Desktop Entry]
Name=Simple OCR
Comment=Simple Linux desktop OCR application using GPUI
Exec=$out/bin/simple-ocr %U
Terminal=false
Type=Application
Categories=Graphics;Photography;OCR;
EOF

    wrapProgram $out/bin/simple-ocr \
      --prefix LD_LIBRARY_PATH : "${libPath}" \
      --prefix PATH : "${tesseract}/bin"
  '';

  meta = with lib; {
    description = "Simple Linux desktop OCR application using GPUI";
    homepage = "https://github.com/sgnay/simple-ocr";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "simple-ocr";
  };
}