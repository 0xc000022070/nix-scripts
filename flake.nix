{
  inputs = {
    nixpkgs.url = "nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = inputs @ {
    self,
    poetry2nix,
    systems,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;

    pkgsFor = eachSystem (system:
      import nixpkgs {
        localSystem = system;
      });

    eachSystem = lib.genAttrs (import systems);
  in rec {
    packages = eachSystem (system: let
      pkgs = pkgsFor.${system};

      entries = {
        dunstify-brightness = ./apps/dunstify-brightness;
        screen-capture-x11 = ./apps/screen-capture-x11;
        playerctl-waybar = ./apps/playerctl-waybar;
        dunstify-sound = ./apps/dunstify-sound;
        cliphist-rofi = ./apps/cliphist-rofi;
        swww-switcher = ./apps/swww-switcher;
        spotify-dbus = ./apps/spotify-dbus;
        rofi-radio = ./apps/rofi-radio;
        nixgrep = ./apps/nixgrep;
        mullx = ./apps/mullx;
      };
    in
      {
        default = self.packages.${system}.rofi-radio;
      }
      // lib.attrsets.mapAttrs (_n: p:
        pkgs.callPackage p {
          inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication;
          inherit pkgs;
        })
      entries);

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
