{pkgs ? import <nixpkgs> {}, ...}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "battery-notifier";
  version = "unstable";

  src = builtins.path {
    name = pname;
    path = ./.;
  };

  nativeBuildInputs = with pkgs; [git cmake];

  # buildInputs = with pkgs; [miniaudio];

  cargoLock = {
    lockFile = ./Cargo.lock;

    outputHashes = {
      "soloud-1.0.5" = "sha256-2Cd5aWfntRawxRSdy+4tJJdTkTeii1ilshQadG6Pybw=";
    };
  };

  preConfigure = ''
    substituteInPlace ./src/main.rs \
    --replace './../assets' $src/assets

    substituteInPlace ./src/main.rs \
      --replace './assets' '${placeholder "out"}/assets'
  '';

  postInstall = ''
    mkdir -p $out/assets/
    cp ./assets/*.png $out/assets/
  '';
}
