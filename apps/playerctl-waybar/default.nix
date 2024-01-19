{
  mkPoetryApplication,
  pkgs ? import <nixpkgs> {},
  ...
}: let
  pname = "playerctl-waybar";
in
  mkPoetryApplication rec {
    python = pkgs.python311;

    projectDir = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };
    pyproject = builtins.path {
      name = "${pname}-pyproject.toml";
      path = ./pyproject.toml;
    };
    poetrylock = builtins.path {
      name = "${pname}-poetry.lock";
      path = ./poetry.lock;
    };

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
