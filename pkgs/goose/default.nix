{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "goose";
 version = "1.47.0";

  src = fetchurl {
    url = "https://github.com/aaif-goose/goose/releases/download/v${version}/goose-x86_64-unknown-linux-gnu.tar.gz";
 sha256 = "sha256-RG4BS9BBL87b6y3uhF1tW/ytYwlEsBKA+zX25P6xESo=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp goose $out/bin/goose
    chmod +x $out/bin/goose
    runHook postInstall
  '';

  meta = with lib; {
    description = "An open-source, extensible AI agent that goes beyond code suggestions";
    homepage = "https://github.com/aaif-goose/goose";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose";
  };
}
