{ pkgs ? import <nixpkgs> { } }:
{
  lib = import ./lib { inherit pkgs; };
  nixosModules = import ./nixos-modules;
  overlays = import ./overlays;
  univpn = pkgs.callPackage ./pkgs/univpn { zipFile = ./pkgs/univpn/univpn-linux-64-10781.19.0.1214.zip; };
  nyaterm = pkgs.callPackage ./pkgs/nyaterm { };
  omp = pkgs.callPackage ./pkgs/omp { };
  sunloginclient = pkgs.callPackage ./pkgs/sunloginclient { };
  rustconn = pkgs.callPackage ./pkgs/rustconn { };
  oxideterm = pkgs.callPackage ./pkgs/oxideterm { };
  velotype = pkgs.callPackage ./pkgs/velotype { };
  pot-translation = pkgs.callPackage ./pkgs/pot-translation { };
  goose = pkgs.callPackage ./pkgs/goose { };
  goose-desktop = pkgs.callPackage ./pkgs/goose-desktop { };
  simple-translation = pkgs.callPackage ./pkgs/simple-translation { };
  simple-ocr = pkgs.callPackage ./pkgs/simple-ocr { };
  deepseek-reasonix = pkgs.callPackage ./pkgs/deepseek-reasonix { };
  ferrite = pkgs.callPackage ./pkgs/ferrite { };
}