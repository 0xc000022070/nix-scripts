{
  mkPoetryApplication,
  pkgs,
  ...
}: let
  pname = "swww-switcher";
in
  mkPoetryApplication {
    python = pkgs.python311;

    projectDir = builtins.path {
      name = "${pname}-source";
      path = ./.;
    };
    pyproject = builtins.path {
      name = "${pname}-pyproject.toml";
      path = ./pyproject.toml;
    };
    poetrylock = builtins.path {
      name = "${pname}-poetry.lock";
      path = ./poetry.lock;
    };
  }
