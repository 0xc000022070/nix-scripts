{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    gobject-introspection
    pkg-config
    playerctl
    cairo
  ];
}
