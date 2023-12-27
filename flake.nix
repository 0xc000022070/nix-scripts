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
  in {
    packages = eachSystem (system: let
      pkgs = pkgsFor.${system};

      entries = {
        dunstify-brightness = ./dunstify-brightness;
        battery-notifier = ./battery-notifier;
        playerctl-waybar = ./playerctl-waybar;
        dunstify-sound = ./dunstify-sound;
        screen-capture = ./screen-capture;
        cliphist-rofi = ./cliphist-rofi;
        swww-switcher = ./swww-switcher;
        spotify-dbus = ./spotify-dbus;
        rofi-radio = ./rofi-radio;
        mullx = ./mullx;
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
