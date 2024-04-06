{
  pkgs ? import <nixpkgs> {},
  powerSupplyBatteryPath ? "/sys/class/power_supply/BAT1",
  ...
}:
pkgs.stdenv.mkDerivation rec {
  name = "batlimit";

  src = builtins.path {
    name = "${name}-source";
    path = ./.;
  };

  postPatch = ''
    substituteInPlace ./main.sh \
      --replace '/sys/class/power_supply/BAT1' '${powerSupplyBatteryPath}'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./main.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    runHook postInstall
  '';
}
