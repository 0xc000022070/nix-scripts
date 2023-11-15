{pkgs ? import <nixpkgs> {}, ...}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "battery-notifier";
  version = "unstable";

  src = builtins.path {
    name = pname;
    path = ./.;
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    substituteInPlace ./src/main.rs \
      --replace './assets' '${placeholder "out"}/assets'
  '';

  postInstall = ''
    mkdir -p $out/assets/
    cp ./assets/* $out/assets/
  '';
}
