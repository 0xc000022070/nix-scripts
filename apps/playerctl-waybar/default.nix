{
  mkPoetryApplication,
  pkgs ? import <nixpkgs> {},
  ...
}: let
  pname = "playerctl-waybar";
in
  mkPoetryApplication rec {
    python = pkgs.python311;

    projectDir = ./.;
    pyproject = ./pyproject.toml;
    poetrylock = ./poetry.lock;

    buildInputs = with pkgs; [
      pkg-config
    ];

    nativeBuildInputs = with pkgs; [
      gobject-introspection
      playerctl
      cairo
    ];

    postInstall = ''
      mv $out/bin/cli $out/bin/${pname}
    '';
  }
