{
  lib,
  fetchFromGitHub,
  buildUBoot,
  m1n1,
  linux-asahi,
}:

buildUBoot rec {
  src = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = "u-boot";
    rev = "asahi-v2026.07-2";
    hash = "sha256-9E79VceZcPw55zj6BBwgIBP/2OrHRS/w3ypGyOWfE6U=";
  };
  version = "2026.07-2-asahi";

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

  postBuild = ''
    # compress so that m1n1 knows U-Boot's size and can find things after it
    gzip -n u-boot-nodtb.bin

    # See m1n1 .github/workflows/release.yml
    cat ${m1n1}/lib/m1n1/m1n1.bin \
        ${linux-asahi.kernel}/dtbs/apple/t60*.dtb \
        ${linux-asahi.kernel}/dtbs/apple/t81*.dtb \
        u-boot-nodtb.bin.gz \
        > m1n1-u-boot.bin
  '';
}
