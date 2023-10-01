{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = inputs:
  # inputs @ {self, ...}:
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
          mullman = ./mullman;
        };
      in
        {
          default = self.packages.${system}.mullman;
        }
        // lib.attrsets.mapAttrs (_n: p: pkgs.callPackage p {inherit pkgs;}) entries);
    };
}
