{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";
    nixgrep = {
      url = "github:0xc000022070/nixgrep";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    systems,
    nixgrep,
    nixpkgs,
    self,
    ...
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
        sys-brightness = ./apps/sys-brightness;
        screen-capture-x11 = ./apps/screen-capture-x11;
        nmcli-wifi-scan-waybar = ./apps/nmcli-wifi-scan-waybar;
        sys-sound = ./apps/sys-sound;
        batlimit = ./apps/batlimit;
        cliphist-rofi = ./apps/cliphist-rofi;
        swww-switcher = ./apps/swww-switcher;
        mullvad-status = ./apps/mullvad-status;
      };
    in
      {
        default = packages.${system}.swww-switcher;

        inherit (nixgrep.packages.${system}) nixgrep;
      }
      // lib.attrsets.mapAttrs (_n: p: pkgs.callPackage p {inherit pkgs;})
      entries);

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
