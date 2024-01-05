{
  packages,
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.battery-notifier;
in {
  options = {
    programs.battery-notifier = {
      enable = mkEnableOption "battery-notifier";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services = {
      battery-notifier = {
        Unit = {
          Description = "A very useful battery notifier for window managers";
        };

        Service = {
          Type = "simple";
          ExecStart = "${packages.${system}.battery-notifier}/bin/battery-notifier";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
