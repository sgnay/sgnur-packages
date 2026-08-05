# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `overlays`,
# `nixosModules`, `homeModules`, `darwinModules` and `flakeModules`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> { } }:

{
  # The `lib`, `overlays`, `nixosModules`, `homeModules`,
  # `darwinModules` and `flakeModules` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  # homeModules = { }; # Home Manager modules
  # darwinModules = { }; # nix-darwin modules
  # flakeModules = { }; # flake-parts modules
  overlays = import ./overlays; # nixpkgs overlays

  univpn = pkgs.callPackage ./pkgs/univpn { zipFile = ./pkgs/univpn/univpn-linux-64-10781.19.0.1214.zip; };  # Leagsoft UniVPN 客户端

  nyaterm = pkgs.callPackage ./pkgs/nyaterm { };  # NyaTerm — modern remote terminal workspace

  omp = pkgs.callPackage ./pkgs/omp { };  # Oh My Pi — terminal coding agent

  sunloginclient = pkgs.callPackage ./pkgs/sunloginclient { }; # Proprietary remote control software (AweSun / Sunlogin Client)

  rustconn = pkgs.callPackage ./pkgs/rustconn { }; # Modern connection manager for Linux with GTK4/Wayland-native interface

  oxideterm = pkgs.callPackage ./pkgs/oxideterm { }; # AI-native workspace for local shells and remote machines

  velotype = pkgs.callPackage ./pkgs/velotype { }; # Native Markdown editor built with Rust and GPUI

  pot-translation = pkgs.callPackage ./pkgs/pot-translation { }; # Pot — Cross-platform translation and OCR software

  goose = pkgs.callPackage ./pkgs/goose { }; # Goose — open-source extensible AI agent CLI

  goose-desktop = pkgs.callPackage ./pkgs/goose-desktop { }; # Goose Desktop — open-source AI agent GUI application

  simple-translation = pkgs.callPackage ./pkgs/simple-translation { }; # Simple Translation — A simple Linux desktop translator written in Rust and egui
}
