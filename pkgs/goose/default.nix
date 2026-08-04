{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "goose";
  version = "1.45.0";

  src = fetchurl {
    url = "https://github.com/aaif-goose/goose/releases/download/v${version}/goose-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "19a66dvdk3zl7d6231d2s4ld4216692jyqn1n1h0mjipqj567nz0";
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
