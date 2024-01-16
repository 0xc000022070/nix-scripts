{pkgs ? import <nixpkgs> {}, ...}:
with pkgs;
  ocamlPackages.buildDunePackage rec {
    pname = "nixgrep";
    version = "unstable";

    src = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };

    propagatedBuildInputs = [ocamlPackages.result];
    doCheck = lib.versionAtLeast ocaml.version "5.0.0";
  }
