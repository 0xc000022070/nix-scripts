{pkgs ? import <nixpkgs> {}, ...}:
with pkgs;
  ocamlPackages.buildDunePackage rec {
    pname = "pstore";
    version = "unstable";

    src = builtins.path {
      name = pname;
      path = ./.;
    };

    propagatedBuildInputs = [ocamlPackages.result];
    doCheck = lib.versionAtLeast ocaml.version "5.0.0";
  }
