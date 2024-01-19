{pkgs ? import <nixpkgs> {}, ...}:
with pkgs;
  buildGoModule rec {
    pname = "rofi-radio";
    version = "unstable";

    src = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };

    nativeBuildInputs = [makeWrapper];

    postInstall = ''
      mkdir -p $out/share/
      cp ./etc/* $out/share/

      wrapProgram $out/bin/${pname} \
        --set ROFI_RADIO_ROFI_CFG $out/share/config.rasi
    '';

    buildTarget = ".";
    vendorSha256 = "sha256-WKIcGAL98gwIz3sG+eooSyf3TJ2iYuLrqb6x9XHdTmM=";
  }
