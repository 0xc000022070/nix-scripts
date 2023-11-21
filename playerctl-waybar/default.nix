{
  mkPoetryApplication,
  pkgs ? import <nixpkgs> {},
  ...
}:
mkPoetryApplication {
  python = pkgs.python311;

  projectDir = ./.;
  pyproject = ./pyproject.toml;
  poetrylock = ./poetry.lock;

  buildInputs = with pkgs; [
    gobject-introspection
    pkg-config
    playerctl
    cairo
  ];
}
