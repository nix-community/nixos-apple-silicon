{
  lib,
  fetchFromGitHub,
  buildUBoot,
  m1n1,
}:

(buildUBoot rec {
  src = fetchFromGitHub {
    # tracking: https://pagure.io/fedora-asahi/uboot-tools/commits/main
    owner = "AsahiLinux";
    repo = "u-boot";
    rev = "asahi-v2025.04-1";
    hash = "sha256-/z37qj26AqsyEBsFT6UEN3GjG6KVsoJOoUB4s9BRDbE=";
  };
  version = "2025.04-1-asahi";

  defconfig = "apple_m1_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [
    "u-boot-nodtb.bin.gz"
    "m1n1-u-boot.bin"
  ];
  extraConfig = ''
    CONFIG_IDENT_STRING=" ${version}"
    CONFIG_VIDEO_FONT_4X6=n
    CONFIG_VIDEO_FONT_8X16=n
    CONFIG_VIDEO_FONT_SUN12X22=n
    CONFIG_VIDEO_FONT_16X32=y
    CONFIG_CMD_BOOTMENU=y
  '';
}).overrideAttrs
  (o: {
    # nixos's downstream patches are not applicable
    patches = [
    ];

    # DTC= flag somehow breaks DTC compilation so we remove it
    makeFlags = builtins.filter (s: (!(lib.strings.hasPrefix "DTC=" s))) o.makeFlags;

    preInstall = ''
      # compress so that m1n1 knows U-Boot's size and can find things after it
      gzip -n u-boot-nodtb.bin
      cat ${m1n1}/build/m1n1.bin arch/arm/dts/t[68]*.dtb u-boot-nodtb.bin.gz > m1n1-u-boot.bin
    '';
  })
