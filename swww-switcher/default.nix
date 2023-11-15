{
  mkPoetryApplication,
  pkgs,
  ...
}:
mkPoetryApplication {
  python = pkgs.python311;

  projectDir = ./.;
  pyproject = ./pyproject.toml;
  poetrylock = ./poetry.lock;
}
