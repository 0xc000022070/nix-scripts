{
  inputs = {
    nixpkgs.url = "nixpkgs";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = inputs:
    with inputs; let
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
          dunstify-sound = ./dunstify-sound;
          screen-capture = ./screen-capture;
          cliphist-rofi = ./cliphist-rofi;
          swww-switcher = ./swww-switcher;
          spotify-dbus = ./spotify-dbus;
          mullx = ./mullx;
        };
      in
        {
          default = self.packages.${system}.dunstify-sound;
        }
        // lib.attrsets.mapAttrs (_n: p: pkgs.callPackage p {inherit pkgs;}) entries);
    };
}
