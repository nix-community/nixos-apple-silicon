{
  lib,
  stdenvNoCC,
  texinfoInteractive,
  writeShellApplication,
  symlinkJoin,
  xdg-utils,
  version,
}:
let
  manual = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "nixos-apple-silicon-manual";
    inherit version;

    src = ./.;

    nativeBuildInputs = [
      texinfoInteractive
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/doc/nixos-apple-silicon
      mkdir -p $out/share/info

      makeinfo nixos-apple-silicon.texi \
        -o $out/share/info/nixos-apple-silicon.info
      makeinfo nixos-apple-silicon.texi \
        --plaintext \
        -o $out/share/doc/nixos-apple-silicon/nixos-apple-silicon.txt
      makeinfo nixos-apple-silicon.texi \
        --html \
        --css-ref=static/manual.css \
        --no-split \
        -o $out/share/doc/nixos-apple-silicon/nixos-apple-silicon.html
      makeinfo nixos-apple-silicon.texi \
        --html \
        --css-ref=../static/manual.css \
        -o $out/share/doc/nixos-apple-silicon/html.d

      cp -r static $out/share/doc/nixos-apple-silicon

      runHook postInstall
    '';

    meta = {
      description = "Manual for installing and maintaining NixOS on Apple Silicon";
      homepage = "https://github.com/nix-community/nixos-apple-silicon";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  });
  startScriptInfo = writeShellApplication {
    name = "start-manual-info";

    runtimeInputs = [
      texinfoInteractive
    ];

    text = ''
      info -d ${manual}/share/info -f ${manual}/share/info/nixos-apple-silicon
    '';
  };

  startScriptWeb = writeShellApplication {
    name = "start-manual-web";

    runtimeInputs = [
      xdg-utils
    ];

    text = ''
      if [[ $# -lt 1 ]]; then
         echo "[Note]: Run this script with any positional arguments to access the split web manual."
         xdg-open ${manual}/share/doc/nixos-apple-silicon/nixos-apple-silicon.html
      else
         xdg-open ${manual}/share/doc/nixos-apple-silicon/html.d/index.html
      fi
    '';
  };

  startScriptWebDarwin =
    if stdenvNoCC.hostPlatform.isDarwin then
      writeShellApplication {
        name = "start-manual-web";

        text = ''
          if [[ $# -lt 1 ]]; then
             echo "[Note]: Run this script with any positional arguments to access the split web manual."
             open ${manual}/share/doc/nixos-apple-silicon/nixos-apple-silicon.html
          else
             open ${manual}/share/doc/nixos-apple-silicon/html.d/index.html
          fi
        '';
      }
    else
      null;
in
symlinkJoin {
  name = "nas-manual";
  paths = [
    manual
    startScriptInfo
    (if !stdenvNoCC.hostPlatform.isDarwin then startScriptWeb else startScriptWebDarwin)
  ];

  meta = manual.meta // {
    mainProgram = "start-manual-web";
  };
}
