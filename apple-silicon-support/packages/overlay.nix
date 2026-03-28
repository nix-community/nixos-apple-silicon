final: prev: {
  linux-asahi = final.callPackage ./linux-asahi { };
  linux-asahi-fairydust = final.callPackage ./linux-asahi-fairydust { };
  uboot-asahi = final.callPackage ./uboot-asahi { };
  mesa =
    if prev.mesa.version == "26.0.5" then
      # Workaround for https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/41040
      prev.mesa.overrideAttrs (old: {
        version = "26.0.4";
        src = final.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "mesa";
          repo = "mesa";
          rev = "mesa-26.0.4";
          hash = "sha256-gsrqhFCxZRrTbA5MMWARrN6lFVp4Q3D5Jz7MDYbXznY=";
        };
      })
    else
      prev.mesa;
}
