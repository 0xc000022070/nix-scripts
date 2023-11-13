{
  poetry2nix,
  pkgs,
  ...
}:
poetry2nix.mkPoetryApplication {
  python = pkgs.python311;

  projectDir = ./.;
  pyproject = ./pyproject.toml;
  poetrylock = ./poetry.lock;
}
