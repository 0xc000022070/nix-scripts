self: {
  config,
  pkgs,
  lib,
  ...
}: let
  hmConfig = config;
in
  with lib; let
    inherit (pkgs.stdenv.hostPlatform) system;

    flake-pkgs = self.packages.${system};
  in {
    # Battery notifier
    options = {
      programs.battery-notifier = {
        enable = mkEnableOption "battery-notifier";
      };
    };

    config = let
      cfg = hmConfig.programs.battery-notifier;
    in
      lib.mkIf cfg.enable {
        systemd.user.services = {
          battery-notifier = {
            Unit = {
              Description = "A very useful battery notifier for window managers";
            };

            Service = {
              Type = "simple";
              ExecStart = "${flake-pkgs.battery-notifier}/bin/battery-notifier";
              Restart = "on-failure";
            };

            Install = {
              WantedBy = ["default.target"];
            };
          };
        };
      };

    # Rofi radio
    options.programs.rofi-radio = let
      broadcasterModule = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "Smooth Chill";
          };

          url = mkOption {
            type = types.str;
            example = "https://media-ssl.musicradio.com/SmoothChill";
          };

          shuffle = mkOption {
            type = types.bool;
            default = false;
            example = true;
          };
        };
      };
    in {
      enable = mkEnableOption "rofi radio";
      broadcasters = mkOption {
        type = types.listOf broadcasterModule;
        default = [];
      };
    };

    config = let
      cfg = hmConfig.programs.rofi-radio;
    in
      mkIf cfg.enable {
        home.packages = [
          flake-pkgs.rofi-radio
        ];

        xdg.configFile."rofi-radio/config.yaml".source = (pkgs.formats.yaml {}).generate "rofi-radio-config" {
          inherit (cfg) broadcasters;
        };
      };
  }
