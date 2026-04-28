# this configuration is intended to have just enough stuff to get the disk,
# display, USB input, and network up so the user can build a real config.
# in the future we will just use the standard NixOS iso

# based vaguely on
# https://github.com/samueldr/cross-system/blob/master/configuration.nix

{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
  ];

  # Adds terminus_font for people with HiDPI displays
  console.packages = [ pkgs.terminus_font ];

  # ISO naming.
  image.fileName = "${config.image.baseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # EFI booting
  isoImage.makeEfiBootable = true;

  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = lib.mkOverride 60 [ ];
  fileSystems = lib.mkOverride 60 config.lib.isoFileSystems;

  boot.postBootCommands =
    let
      inherit (config.hardware.asahi.pkgs) asahi-fwextract;
    in
    ''
      for o in $(</proc/cmdline); do
        case "$o" in
          live.nixos.passwd=*)
            set -- $(IFS==; echo $o)
            echo "nixos:$2" | ${pkgs.shadow}/bin/chpasswd
            ;;
        esac
      done

      echo Extracting Asahi firmware...
      mkdir -p /tmp/.fwsetup/{esp,extracted}

      mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp

      if [ -f /tmp/.fwsetup/esp/vendorfw/firmware.cpio ]; then
        cpio_src=/tmp/.fwsetup/esp/vendorfw/firmware.cpio

      elif [ -d /tmp/.fwsetup/esp/asahi ] && [ -f /tmp/.fwsetup/esp/asahi/all_firmware.tar.gz ]; then
        ${asahi-fwextract}/bin/asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
        cpio_src=/tmp/.fwsetup/extracted/firmware.cpio

      else
        echo "Warning: No Asahi firmware found in ESP. Wi-Fi and ALS may not work."
        cpio_src=
      fi

      if [ -n "$cpio_src" ]; then
        pushd /tmp/.fwsetup/
        cat "$cpio_src" | ${pkgs.cpio}/bin/cpio -id --quiet --no-absolute-filenames
        mkdir -p /lib/firmware
        if [ -d vendorfw ]; then
          cp -a vendorfw/. /lib/firmware
        else
          echo "Warning: firmware archive did not contain vendorfw/ directory"
        fi
        popd
      fi

      umount /tmp/.fwsetup/esp
      rm -rf /tmp/.fwsetup
    '';

  # can't legally be incorporated into the installer image
  # (and is automatically extracted at boot above)
  hardware.asahi.extractPeripheralFirmware = false;

  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  environment.systemPackages = with pkgs; [ wormhole-william ];

  # save space and compilation time. might revise?
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;
  services.pulseaudio.enable = false;
  hardware.asahi.setupAsahiSound = false;
  system.extraDependencies = lib.mkForce [ ];

  # Enable iwd and make NetworkManager, enabled by default, use iwd for wifi
  # We use iwd instead of wpa_supplicant because it can't use WPA3-SAE on broadcom chips that are used on macs,
  # and it is harder to use and less mainained than iwd in general
  networking.networkmanager.wifi.backend = "iwd";

  nixpkgs.overlays =
    lib.optionals (config.nixpkgs.hostPlatform.system != config.nixpkgs.buildPlatform.system)
      [
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

          # avoids broken cross-compilation
          # https://github.com/NixOS/nixpkgs/pull/460394/
          libcap = prev.libcap.override {
            withGo = false;
          };
        })
      ];

  # avoids the need to cross-compile gobject introspection stuff which works
  # now but is slow and unnecessary
  security.polkit.enable = lib.mkForce false;

  # get rid of warning about non-ideal mdam config file
  # (we want to keep it enabled in case someone needs to use it)
  boot.swraid.mdadmConf = ''
    PROGRAM ${pkgs.coreutils}/bin/true
  '';

  # profiles/base.nix assumes the default LTS kernel, and thus enables ZFS.
  # We do not use LTS kernel, thus disable ZFS to match latest-kernel specialisation
  # and avoid breaking the installer image when ZFS does not build against our kernel.
  boot.supportedFilesystems.zfs = false;

  # avoid error that flakes must be enabled when nixos-install uses <nixpkgs>
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;

  # get rid of warning that stateVersion is unset
  system.stateVersion = lib.mkDefault lib.trivial.release;
}
