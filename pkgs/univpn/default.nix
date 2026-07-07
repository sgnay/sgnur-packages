{ pkgs }:

let
  version = "10781.19.0.1214";
in
pkgs.runCommand "univpn-${version}" {
  nativeBuildInputs = [ pkgs.unzip pkgs.gzip pkgs.binutils ];
} ''
  unzip -qo ${./../../etc/nixos/pkgs/univpn-linux-64-${version}.zip}
  tail -n +258 univpn-linux-amd64-${version}.run > UniVPN.tar.gz
  mkdir -p $out
  tar -xzf UniVPN.tar.gz -C $out
  chmod +x $out/UniVPN $out/serviceclient/UniVPNCS $out/promote/UniVPNPromoteService $out/UniVPNUpdate
  mkdir -p $out/certificate
''
