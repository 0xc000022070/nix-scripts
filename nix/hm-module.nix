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
    tomlFormat = pkgs.formats.toml {};

    flake-pkgs = self.packages.${system};
  in {
    options.programs = {
      battery-notifier = {
        enable = mkEnableOption "battery-notifier";

        settings = types.submodule {
          options = {
            sleep_ms = mkOption {
              type = types.int;
              default = 700;
            };

            reminder_threshold = mkOption {
              type = types.int;
              default = 30;
            };

            warn_threshold = mkOption {
              type = types.int;
              default = 15;
            };

            threat_threshold = mkOption {
              type = types.int;
              default = 5;
            };
          };
        };
      };

      rofi-radio = let
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
    };

    config = let
      ifOrEmptySet = cond: v:
        if cond
        then v
        else {};
    in
      (
        let
          cfg = hmConfig.programs.battery-notifier;
        in
          ifOrEmptySet cfg.enable {
            assertions = [
              {
                assertion = builtins.length (lib.attrsets.attrValues (builtins.filterAttrs (k: v: lib.strings.hasSuffix k "threshold" && v >= 0 && v <= 100) cfg.settings)) == 0;
                message = "threshold values must be greater equal than 0 and less equal than 100";
              }
              {
                assertion = cfg.settings.reminder_threshold > cfg.settings.warn_threshold;
                message = "'reminder' threshold must be greater than 'warn' threshold";
              }
              {
                assertion = cfg.settings.warn_threshold > cfg.settings.threat_threshold;
                message = "'warn' threshold must be greater than 'threat' threshold";
              }
              {
                assertion = cfg.settings.sleep_ms > 0;
                message = "sleep time must be greater than zero";
              }
            ];

            xdg.configFile."battery-notifier/config.toml".source = tomlFormat.generate "battery-notifier-config" cfg.settings;

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
          }
      )
      // (
        let
          cfg = hmConfig.programs.rofi-radio;
        in
          ifOrEmptySet cfg.enable {
            home.packages = [
              flake-pkgs.rofi-radio
            ];

            xdg.configFile."rofi-radio/config.yaml".source = (pkgs.formats.yaml {}).generate "rofi-radio-config" {
              inherit (cfg) broadcasters;
            };
          }
      );
  }
