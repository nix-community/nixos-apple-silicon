# this configuration is intended to have just enough stuff to get the disk,
# display, USB input, and network up so the user can build a real config.
# in the future we will just use the standard NixOS iso

# based vaguely on
# https://github.com/samueldr/cross-system/blob/master/configuration.nix

{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
  ];

  # Adds terminus_font for people with HiDPI displays
  console.packages = [ pkgs.terminus_font ];

  # ISO naming.
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # EFI booting
  isoImage.makeEfiBootable = true;

  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = lib.mkOverride 60 [ ];
  fileSystems = lib.mkOverride 60 config.lib.isoFileSystems;

  boot.postBootCommands = ''
    for o in $(</proc/cmdline); do
      case "$o" in
        live.nixos.passwd=*)
          set -- $(IFS==; echo $o)
          echo "nixos:$2" | ${pkgs.shadow}/bin/chpasswd
          ;;
      esac
    done
  '';

  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  environment.systemPackages = with pkgs; [
    gptfdisk
    parted
    cryptsetup
    curl
    wget
    wormhole-william
  ];

  # save space and compilation time. might revise?
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;
  services.pulseaudio.enable = false;
  hardware.asahi.setupAsahiSound = false;
  # avoid including non-reproducible dbus docs
  documentation.doc.enable = false;
  documentation.info.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkOverride 49 false;
  system.extraDependencies = lib.mkForce [ ];

  # Disable wpa_supplicant because it can't use WPA3-SAE on broadcom chips that are used on macs and it is harder to use and less mainained than iwd in general
  networking.wireless.enable = false;
  # Enable iwd
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      # disabling pcsclite avoids the need to cross-compile gobject
      # introspection stuff which works now but is slow and unnecessary
      libfido2 = prev.libfido2.override {
        withPcsclite = false;
      };
      openssh = prev.openssh.overrideAttrs (old: {
        # we have to cross compile openssh ourselves for whatever reason
        # but the tests take quite a long time to run
        doCheck = false;
      });

      # avoids having to compile a bunch of big things (like texlive) to
      # compute translations
      util-linux = prev.util-linux.override {
        translateManpages = false;
      };
    })
  ];

  # avoids the need to cross-compile gobject introspection stuff which works
  # now but is slow and unnecessary
  security.polkit.enable = lib.mkForce false;

  # bootspec generation is currently broken under cross-compilation
  boot.bootspec.enable = false;

  # get rid of warning about non-ideal mdam config file
  # (we want to keep it enabled in case someone needs to use it)
  boot.swraid.mdadmConf = ''
    PROGRAM ${pkgs.coreutils}/bin/true
  '';

  # avoid error that flakes must be enabled when nixos-install uses <nixpkgs>
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;

  # get rid of warning that stateVersion is unset
  system.stateVersion = lib.mkDefault lib.trivial.release;
}
