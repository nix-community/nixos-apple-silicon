# the Asahi Linux kernel and options that must go along with it

{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.hardware.asahi.enable {
    boot.kernelPackages =
      let
        pkgs' = config.hardware.asahi.pkgs;
      in
      pkgs'.linux-asahi.override {
        _kernelPatches = config.boot.kernelPatches;
      };

    # we definitely want to use CONFIG_ENERGY_MODEL, and
    # schedutil is a prerequisite for using it
    # source: https://www.kernel.org/doc/html/latest/scheduler/sched-energy.html
    powerManagement.cpuFreqGovernor = lib.mkOverride 800 "schedutil";

    boot.initrd.availableKernelModules = [
      # list of initrd modules stolen from
      # https://github.com/AsahiLinux/asahi-scripts/blob/f461f080a1d2575ae4b82879b5624360db3cff8c/initcpio/install/asahi
      "apple-mailbox"
      "apple_nvmem_spmi"
      "nvme_apple"
      "pinctrl-apple-gpio"
      "macsmc"
      "macsmc-power"
      "macsmc-input"
      "macsmc-hwmon"
      "macsmc-reboot"
      "i2c-pasemi-platform"
      "tps6598x"
      "apple-dart"
      "dwc3"
      "dwc3-of-simple"
      "xhci-pci"
      "pcie-apple"
      "gpio_macsmc"
      "phy-apple-atc"
      "nvmem_apple_efuses"
      "spi-apple"
      "spi-hid-apple"
      "spi-hid-apple-of"
      "rtc-macsmc"
      "spmi-apple-controller"
      "apple-dockchannel"
      "dockchannel-hid"
      "apple-rtkit-helper"

      # additional stuff necessary to boot off USB for the installer
      # and if the initrd (i.e. stage 1) goes wrong
      "usb-storage"
      "xhci-plat-hcd"
      "usbhid"
      "hid_generic"
    ];

    boot.kernelParams = [
      "earlycon"
      "console=tty0"
      "boot.shell_on_fail"
      # Apple's SSDs are slow (~dozens of ms) at processing flush requests which
      # slows down programs that make a lot of fsync calls. This parameter sets
      # a delay in ms before actually flushing so that such requests can be
      # coalesced. Be warned that increasing this parameter above zero (default
      # is 1000) has the potential, though admittedly unlikely, risk of
      # UNBOUNDED data corruption in case of power loss!!!! Don't even think
      # about it on desktops!!
      "nvme_apple.flush_interval=0"
    ];

    # U-Boot does not support EFI variables
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    # U-Boot does not support switching console mode
    boot.loader.systemd-boot.consoleMode = "0";

    # GRUB has to be installed as removable if the user chooses to use it
    boot.loader.grub = lib.mkDefault {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };

    # autosuspend was enabled as safe for the PCI SD card reader
    # "Genesys Logic, Inc GL9755 SD Host Controller [17a0:9755] (rev 01)"
    # by recent systemd versions, but this has a "negative interaction"
    # with our kernel/SoC and causes random boot hangs. disable it!
    services.udev.extraHwdb = ''
      pci:v000017A0d00009755*
        ID_AUTOSUSPEND=0
    '';
  };

  imports = [
    (lib.mkRemovedOptionModule [
      "hardware"
      "asahi"
      "addEdgeKernelConfig"
    ] "All edge kernel config options are now the default.")
    (lib.mkRemovedOptionModule [
      "hardware"
      "asahi"
      "experimentalGPUInstallMode"
    ] "This option became unnecessary with asahi support landing in mainline mesa.")
    (lib.mkRemovedOptionModule [
      "hardware"
      "asahi"
      "useExperimentalGPUDriver"
    ] "This option became unnecessary with asahi support landing in mainline mesa.")
    (lib.mkRemovedOptionModule [ "hardware" "asahi" "withRust" ] "Rust support is now the default.")
  ];
}
