{pkgs ? import <nixpkgs> {}, ...}:
with pkgs; let
  mainProgram = "mullvad-status";
in
  ocamlPackages.buildDunePackage rec {
    pname = "mullvad_status";
    version = "unstable";

    src = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };

    postInstall = ''
      mv $out/bin/${pname} $out/bin/${mainProgram}
    '';

    # checkInputs = [alcotest ppx_let];
    # buildInputs = [ocaml-syntax-shims];
    propagatedBuildInputs = [ocamlPackages.result];
    doCheck = lib.versionAtLeast ocaml.version "5.0.0";

    meta = {inherit mainProgram;};
  }
