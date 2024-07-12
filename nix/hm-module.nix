self: {
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  inherit (pkgs.stdenv.hostPlatform) system;

  flake-pkgs = self.packages.${system};
in {
  options.programs = {
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
  in (
    let
      cfg = config.programs.rofi-radio;
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
