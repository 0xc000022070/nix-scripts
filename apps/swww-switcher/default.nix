{pkgs, ...}: let
  pname = "swww-switcher";
  py = pkgs.python313;
in
  py.pkgs.buildPythonApplication rec {
    inherit pname;
    version = "0.1.1";

    src = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };

    pyproject = true;
    build-system = [py.pkgs.setuptools];
    dependencies = [py.pkgs.autopep8];

    meta.mainProgram = "cli";
  }
