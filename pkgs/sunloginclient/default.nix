{ lib
, stdenv
, fetchurl
, dpkg
, makeWrapper
, gtk3
, glib
, cairo
, pango
, atk
, gdk-pixbuf
, libnotify
, libepoxy
, libappindicator-gtk3
, webkitgtk_4_1
, util-linux
, libxcrypt-legacy
, zlib
, dbus
, libdrm
, libxkbcommon
, libX11
, libXext
, libXfixes
, libXrandr
, libXinerama
, libXcursor
, libXi
, libXtst
, libICE
, libSM
, libxcb
, gsettings-desktop-schemas
, alsa-lib
, nss
, nspr
, fontconfig
, freetype
, patchelf
, libXrender
, glib-networking
}:

stdenv.mkDerivation rec {
  pname = "sunloginclient";
  version = "16.5.0.30560";

  src = fetchurl {
    url = "https://down.oray.com/sl/linux/awesun-${version}-x86_64.deb";
    sha256 = "eda3fffe6d5324afbc4f939f0cb85c08b7851efad3c01878621474ec7503d10f";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    patchelf
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    gtk3
    glib
    cairo
    pango
    atk
    gdk-pixbuf
    libnotify
    libepoxy
    libappindicator-gtk3
    webkitgtk_4_1
    util-linux.lib
    libxcrypt-legacy
    zlib
    dbus
    libdrm
    libxkbcommon
    libX11
    libXext
    libXfixes
    libXrandr
    libXrender
    libXinerama
    libXcursor
    libXi
    libXtst
    libICE
    libSM
    libxcb
    alsa-lib
    nss
    nspr
    fontconfig
    freetype
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/local/awesun $out/awesun

    # Install desktop entry
    mkdir -p $out/share/applications
    if [ -f usr/share/applications/awesun.desktop ]; then
      cp usr/share/applications/awesun.desktop $out/share/applications/sunloginclient.desktop
      substituteInPlace $out/share/applications/sunloginclient.desktop \
        --replace "Exec=/usr/local/awesun/awesun" "Exec=sunloginclient" \
        --replace "Icon=/usr/local/awesun/awesun.png" "Icon=sunloginclient"
    fi

    # Install icon
    mkdir -p $out/share/pixmaps
    if [ -f usr/local/awesun/awesun.png ]; then
      cp usr/local/awesun/awesun.png $out/share/pixmaps/sunloginclient.png
    fi

    # Patchelf only the background helper binaries (leaves the GUI launcher unpatchelfed for verification)
    interpreter=$(cat $NIX_CC/nix-support/dynamic-linker)
    rpath="${lib.makeLibraryPath buildInputs}:$out/awesun/lib"
    for f in $out/awesun/bin/*; do
      if [ -f "$f" ]; then
        echo "Patchelfing background binary: $f"
        patchelf --set-interpreter "$interpreter" --set-rpath "$rpath" "$f" || true
      fi
    done

    # Create wrappers in bin
    mkdir -p $out/bin

    # Wrap the GUI executable
    makeWrapper $out/awesun/awesun $out/bin/sunloginclient \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}:$out/awesun/lib \
      --prefix NIX_LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}:$out/awesun/lib \
      --prefix XDG_DATA_DIRS : ${gtk3}/share/gsettings-schemas/gtk+3-${gtk3.version}:${gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${gsettings-desktop-schemas.version} \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"

    # Wrap the daemon executable
    makeWrapper $out/awesun/bin/awesun_daemon $out/bin/sunloginclient-daemon \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}:$out/awesun/lib \
      --prefix NIX_LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}:$out/awesun/lib \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Proprietary remote control software (AweSun / Sunlogin Client)";
    homepage = "https://sunlogin.oray.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ {
      name = "sgnay";
      github = "sgnay";
    } ];
  };
}
