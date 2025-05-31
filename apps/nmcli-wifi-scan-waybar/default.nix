{pkgs ? import <nixpkgs> {}, ...}: let
  runtimePackages = with pkgs; [
    networkmanager
    gawk
  ];
in
  pkgs.stdenv.mkDerivation rec {
    name = "nmcli-wifi-scan-waybar";

    src = builtins.path {
      name = "${name}-source";
      path = ./.;
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];

    propagatedBuildInputs = runtimePackages;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      cp ./main.sh $out/bin/${name}
      chmod +x $out/bin/${name}

      runHook postInstall
    '';

    postInstall = ''
      wrapProgram $out/bin/${name} \
        --prefix PATH : ${pkgs.lib.makeBinPath runtimePackages}
    '';

    meta.mainProgram = name;
  }
