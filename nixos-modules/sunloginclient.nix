{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sunloginclient;
  sunloginclient = pkgs.sunloginclient;

  # Wrapper to run the GUI client with GSettings schema paths
  wrapper = pkgs.writeShellScriptBin "sunloginclient" ''
    export XDG_DATA_DIRS="${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}:''${XDG_DATA_DIRS:-}"
    export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules"
    export LD_LIBRARY_PATH="/usr/local/awesun/lib:${lib.makeLibraryPath [ pkgs.webkitgtk_4_1 pkgs.libsoup_3 pkgs.gtk3 pkgs.libepoxy pkgs.libappindicator-gtk3 pkgs.libnotify pkgs.libxcrypt-legacy ]}:''${LD_LIBRARY_PATH:-}"
    export NIX_LD_LIBRARY_PATH="/usr/local/awesun/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.util-linux.lib pkgs.webkitgtk_4_1 pkgs.libsoup_3 pkgs.gtk3 pkgs.libepoxy pkgs.libappindicator-gtk3 pkgs.libnotify pkgs.libxcrypt-legacy ]}:''${NIX_LD_LIBRARY_PATH:-}"
    cd /usr/local/awesun
    exec /usr/local/awesun/awesun "$@"
  '';

  desktopEntry = pkgs.runCommand "sunloginclient.desktop" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/sunloginclient.desktop <<'EOF'
[Desktop Entry]
Name=SunloginClient
Comment=Proprietary remote control software (AweSun / Sunlogin Client)
Exec=sunloginclient
Icon=/usr/local/awesun/awesun.png
Terminal=false
Type=Application
Categories=Network;
StartupNotify=true
EOF
  '';
in
{
  options.services.sunloginclient = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Sunlogin (AweSun) client service and GUI";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ wrapper desktopEntry ];

    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      util-linux
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
      libsoup_3
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

    systemd.services.sunloginclient = {
      description = "Sunlogin (AweSun) remote control daemon";
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gawk pkgs.coreutils pkgs.gnugrep pkgs.bash pkgs.procps ];
      environment = {
        GIO_EXTRA_MODULES = "${pkgs.glib-networking}/lib/gio/modules";
        LD_LIBRARY_PATH = "/usr/local/awesun/lib";
        NIX_LD_LIBRARY_PATH = "/usr/local/awesun/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.util-linux.lib pkgs.gtk3 pkgs.libnotify pkgs.libepoxy pkgs.libappindicator-gtk3 pkgs.webkitgtk_4_1 pkgs.libxcrypt-legacy pkgs.zlib pkgs.dbus pkgs.libdrm pkgs.libxkbcommon pkgs.libX11 pkgs.libXext pkgs.libXfixes pkgs.libXrandr pkgs.libXinerama pkgs.libXcursor pkgs.libXi pkgs.libXtst pkgs.libICE pkgs.libSM pkgs.libxcb pkgs.alsa-lib pkgs.nss pkgs.nspr ]}";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "/usr/local/awesun/bin/awesun_daemon -m server -name awesun";
        KillMode = "control-group";
        Restart = "always";
        RestartSec = 5;
      };
    };

    system.activationScripts.sunloginclient = stringAfter [ "binsh" "users" ] ''
      echo "Setting up Sunlogin (AweSun) client under /usr/local/awesun..."
      rm -rf /usr/local/awesun
      mkdir -p /usr/local/awesun
      cp -r ${sunloginclient}/awesun/* /usr/local/awesun/
      chmod -R u+w /usr/local/awesun/

      # Create /usr/share/applications/awesun.desktop to satisfy daemon cp expectation
      mkdir -p /usr/share/applications
      cp ${sunloginclient}/share/applications/sunloginclient.desktop /usr/share/applications/awesun.desktop || true

      # Create runtime log directory (matches upstream postinst)
      mkdir -p /var/log/awesun
      chmod 777 /var/log/awesun

      # Create configuration file if it doesn't exist
      if [ ! -f /etc/orayconfig.conf ]; then
        touch /etc/orayconfig.conf
        chmod 644 /etc/orayconfig.conf
      fi
    '';
  };
}
