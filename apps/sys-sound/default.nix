let
  defaultBarColor = "#ebdbb2";
in
  {
    pkgs ? import <nixpkgs> {},
    barColor ? defaultBarColor,
    ...
  }
  : let
    runtimePackages = with pkgs; [
      pulseaudio
      dunst
    ];
  in
    pkgs.stdenv.mkDerivation rec {
      name = "sys-sound";

      src = builtins.path {
        name = "${name}-source";
        path = ./.;
      };

      nativeBuildInputs = with pkgs; [
        makeWrapper
      ];

      propagatedBuildInputs = runtimePackages;

      postPatch = ''
        substituteInPlace ./main.sh \
          --replace 'path/to/assets' '${placeholder "out"}/assets'

        substituteInPlace ./main.sh \
          --replace 'bar-color-placeholder' '${barColor}'
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/

        mkdir -p $out/bin/
        cp ./main.sh $out/bin/${name}
        chmod +x $out/bin/${name}

        mkdir -p $/out/assets/
        cp -r $src/assets/ $out/assets/

        runHook postInstall
      '';

      postInstall = ''
        wrapProgram ${placeholder "out"}/bin/${name} \
          --prefix PATH : ${pkgs.lib.makeBinPath runtimePackages}
      '';

      meta.mainProgram = name;
    }
