{
  sources ? builtins.fromJSON (builtins.readFile ./npins.json),
  system ? builtins.currentSystem,
  nixpkgsBranch ? "nixos-unstable",
  nixpkgs ? fetchTarball {
    url = sources.pins.${nixpkgsBranch}.url;
    sha256 = sources.pins.${nixpkgsBranch}.hash;
  },
  pkgs ? import nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  crossCompPkgs ?
    if (system == "aarch64-linux") then
      pkgs
    else
      import nixpkgs {
        crossSystem.system = "aarch64-linux";
        localSystem.system = system;
        config = { };
        overlays = [ ];
      },
}:
let
  formatter = pkgs.nixfmt-tree;

  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      npins
      formatter
    ];

    shellHook = ''
      export NIX_PATH="nixpkgs=${builtins.storePath pkgs.path}"
    '';
  };

  overlays = {
    apple-silicon-overlay = import ./apple-silicon-support/packages/overlay.nix;
  };

  nixosModules = {
    apple-silicon-support = ./apple-silicon-support;
  };

  installer-bootstrap =
    let
      installer-system = crossCompPkgs.callPackage ./iso-configuration {
        inherit system;
      };
    in
    installer-system.config.system.build.isoImage.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or { }) // {
        config = installer-system.config;
      };
    });

  packages = {
    linux-asahi = (crossCompPkgs.callPackage ./apple-silicon-support/packages/linux-asahi { }).kernel;
    uboot-asahi = crossCompPkgs.callPackage ./apple-silicon-support/packages/uboot-asahi { };
  };
in
{
  inherit
    formatter
    shell
    overlays
    nixosModules
    installer-bootstrap
    packages
    ;
}
