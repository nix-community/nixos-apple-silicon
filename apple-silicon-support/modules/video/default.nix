{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.asahi;
in
{
  config = lib.mkIf (cfg.enable && cfg.avd.enable) {
    hardware.firmware = [
      (cfg.pkgs.avd-fw.override {
        inherit (cfg.avd) codecs;
      })
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
    codecs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "all_free" ];
      description = ''
        The codecs that the installed firmware will support, default is `all_free`, which only includes `av1` and `vp9` decode support. `all` includes all codec support, or you can manually specify codec names in the list
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
