final: prev: {
  linux-asahi = final.callPackage ./linux-asahi { };
  uboot-asahi = final.callPackage ./uboot-asahi { };
  nas-manual = final.callPackage ./nas-manual { version = "stub"; };
}
