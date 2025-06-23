{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  lsp-plugins,
  bankstown-lv2,
  triforce-lv2,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "asahi-audio";
  # tracking: https://src.fedoraproject.org/rpms/asahi-audio
  version = "3.4";

  src = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = "asahi-audio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7AuPkR/M1a4zB9+dJuOuv9uTp+kIqPlxVOXipsyGGz8=";
  };

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  fixupPhase = ''
    runHook preFixup

    for config_file in $(find $out -type f -not -name '*.wav') ; do
        substituteInPlace $config_file --replace-warn "/usr/" "$out/"
    done

    runHook postFixup
  '';

  passthru = {
    updateScript = nix-update-script { };
    requiredLv2Packages = [
      lsp-plugins
      bankstown-lv2
      triforce-lv2
    ];
  };
})
