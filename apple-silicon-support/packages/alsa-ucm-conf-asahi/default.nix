{
  lib,
  fetchFromGitHub,
  alsa-ucm-conf,
}:

(alsa-ucm-conf.overrideAttrs (
  oldAttrs:
  let
    versionAsahi = "8";

    srcAsahi = fetchFromGitHub {
      # tracking: https://src.fedoraproject.org/rpms/alsa-ucm-asahi
      owner = "AsahiLinux";
      repo = "alsa-ucm-conf-asahi";
      rev = "v${versionAsahi}";
      hash = "sha256-FPrAzscc1ICSCQSqULaGLqG4UCq8GZU9XLV7TUSBBRM=";
    };
  in
  {
    name = "${oldAttrs.pname}-${oldAttrs.version}-asahi-${versionAsahi}";

    postInstall = oldAttrs.postInstall or "" + ''
      cp -r ${srcAsahi}/ucm2 $out/share/alsa
    '';
  }
))
