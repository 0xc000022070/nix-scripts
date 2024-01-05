{
  packages,
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.pstore;
in {
  options = {
    programs.pstore = {
      enable = mkEnableOption "pstore";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      packages.${system}.pstore
    ];
  };
}
