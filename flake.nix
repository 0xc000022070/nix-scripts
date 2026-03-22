{
  inputs = {
    nixpkgs.url = "nixpkgs";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = {
    systems,
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
  in rec {
    overlays.default = final: prev: {
      scripts =
        lib.attrsets.mapAttrs (_n: p: final.callPackage p {}) entries;
    };

    overlay = overlays.default;

    packages = eachSystem (system: let
      pkgs = pkgsFor.${system};
    in
      {
        default = packages.${system}.swww-switcher;
      }
      // lib.attrsets.mapAttrs (_n: p: pkgs.callPackage p {inherit pkgs;})
      entries);

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
