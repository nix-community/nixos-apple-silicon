final: prev: {
  linux-asahi = final.callPackage ./linux-asahi { };
  m1n1 = final.callPackage ./m1n1 { };
  uboot-asahi = final.callPackage ./uboot-asahi { };
  mesa-asahi-edge = final.callPackage ./mesa-asahi-edge { };
}
