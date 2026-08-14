{
  lib,
  stdenv,
  fetchurl,
  glibc,
}:
stdenv.mkDerivation rec {
  pname = "oh-my-pi";
  version = "17.2.12";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    sha256 = "0c3gk620dk1llg0m0x2vbnhm3mwkx4z2nndx6fa9wnlxy0dk6xbc";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/omp
    cp $src $out/share/omp/omp-unpatched
    chmod +x $out/share/omp/omp-unpatched

    cat > $out/bin/omp <<EOF
#!/bin/sh
exec ${glibc}/lib/ld-linux-x86-64.so.2 \\
  --library-path ${glibc}/lib:${stdenv.cc.cc.lib}/lib \\
  $out/share/omp/omp-unpatched \\
  "\$@"
EOF
    chmod +x $out/bin/omp
    runHook postInstall
  '';

  meta = with lib; {
    description = "A terminal-based AI coding agent designed for open, terminal-native workflows";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "omp";
  };
}
