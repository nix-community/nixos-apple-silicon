{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hardware.asahi;
in
{
  config = lib.mkIf (cfg.enable && cfg.avd.enable) {
    hardware.firmware = [
      pkgs.avd-fw
    ];

    hardware.graphics = lib.mkIf (cfg.avd.vaapi-support) {
      enable = true;
      extraPackages = [
        cfg.pkgs.asahi-va-driver
      ];
    };

    environment.sessionVariables = lib.mkIf (cfg.avd.vaapi-support) {
      LIBVA_DRIVER_NAME = "asahi";
    };
  };

  options.hardware.asahi.avd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.asahi.enable;
      description = ''
        Setup the firmware required for the Apple Video Decoder to work properly.
      '';
    };
    vaapi-support = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use asahi-va-driver to expose a vaapi interface with AVD (Experimental)
      '';
    };
  };
}
