{ config, pkgs, lib, ... }:
{
  imports = [
    ./kernel
    ./peripheral-firmware
    ./boot-m1n1
    ./sound
  ];

  config = let
      cfg = config.hardware.asahi;
    in lib.mkIf cfg.enable {
      nixpkgs.overlays = lib.mkBefore [ cfg.overlay ];

      # patch systemd-boot to boot in Apple Silicon UEFI environment.
      # This regression only appeared in systemd 256.7.
      # see https://github.com/NixOS/nixpkgs/pull/355290
      # and https://github.com/systemd/systemd/issues/35026
      systemd.package = let
        systemdBroken = (pkgs.systemd.version == "256.7");

        systemdPatched = pkgs.systemd.overrideAttrs (old: {
          patches = let
            oldPatches = (old.patches or []);
            # not sure why there are non-paths in there but oh well
            patchNames = (builtins.map (p: if ((builtins.typeOf p) == "path") then builtins.baseNameOf p else "") oldPatches);
            fixName = "0019-Revert-boot-Make-initrd_prepare-semantically-equival.patch";
            alreadyPatched = builtins.elem fixName patchNames;
          in oldPatches ++ lib.optionals (!alreadyPatched) [
            (pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/NixOS/nixpkgs/125e99477b0ac0a54b7cddc6c5a704821a3074c7/pkgs/os-specific/linux/systemd/${fixName}";
              hash = "sha256-UW3DZiaykQUUNcGA5UFxN+/wgNSW3ufxDDCZ7emD16o=";
            })
          ];
        });
      in if systemdBroken then systemdPatched else pkgs.systemd;

      hardware.asahi.pkgs =
        if cfg.pkgsSystem != "aarch64-linux"
        then
          import (pkgs.path) {
            crossSystem.system = "aarch64-linux";
            localSystem.system = cfg.pkgsSystem;
            overlays = [ cfg.overlay ];
          }
        else pkgs;
    };

  options.hardware.asahi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the basic Asahi Linux components, such as kernel and boot setup.
      '';
    };

    pkgsSystem = lib.mkOption {
      type = lib.types.str;
      default = "aarch64-linux";
      description = ''
        System architecture that should be used to build the major Asahi
        packages, if not the default aarch64-linux. This allows installing from
        a cross-built ISO without rebuilding them during installation.
      '';
    };

    pkgs = lib.mkOption {
      type = lib.types.raw;
      description = ''
        Package set used to build the major Asahi packages. Defaults to the
        ambient set if not cross-built, otherwise re-imports the ambient set
        with the system defined by `hardware.asahi.pkgsSystem`.
      '';
    };

    overlay = lib.mkOption {
      type = lib.mkOptionType {
        name = "nixpkgs-overlay";
        description = "nixpkgs overlay";
        check = lib.isFunction;
        merge = lib.mergeOneOption;
      };
      default = import ../packages/overlay.nix;
      defaultText = "overlay provided with the module";
      description = ''
        The nixpkgs overlay for asahi packages.
      '';
    };
  };
}
