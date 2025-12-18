{
  lib,
  stdenvNoCC,
  texinfoInteractive,
  writeShellApplication,
  symlinkJoin,
  xdg-utils,
}:
let
  manual = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "nixos-apple-silicon-manual";
    version = "2025-11-18-next";

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

    runtimeInputs = lib.optionals (!stdenvNoCC.hostPlatform.isDarwin) [
      xdg-utils
    ];

    text =
      let
        openCmd = if stdenvNoCC.hostPlatform.isDarwin then "open" else "xdg-open";
      in
      ''
        if [[ $# -lt 1 ]]; then
           echo "[Note]: Run this script with any positional arguments to access the split web manual."
           ${openCmd} ${manual}/share/doc/nixos-apple-silicon/nixos-apple-silicon.html
        else
           ${openCmd} ${manual}/share/doc/nixos-apple-silicon/html.d/index.html
        fi
      '';
  };
in
symlinkJoin {
  name = "nas-manual";
  paths = [
    manual
    startScriptInfo
    startScriptWeb
  ];

  meta = manual.meta // {
    mainProgram = "start-manual-web";
  };
}
