{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{
  options.hardware.asahi = {
    setupAsahiSound = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.asahi.enable;
      description = ''
        Set up the Asahi DSP components so that the speakers and headphone jack
        work properly and safely.
      '';
    };
  };

  config =
    let
      cfg = config.hardware.asahi;
    in
    lib.mkIf (cfg.setupAsahiSound && cfg.enable) (
      lib.mkMerge [
        {
          # can't be used by Asahi sound infrastructure
          services.pulseaudio.enable = false;
          # enable pipewire to run real-time and avoid audible glitches
          security.rtkit.enable = true;
          # set up pipewire with the supported capabilities (instead of pulseaudio)
          # and asahi-audio configs and plugins
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;

            configPackages = [ pkgs.asahi-audio ];

            wireplumber = {
              enable = true;

              configPackages = [ pkgs.asahi-audio ];
            };
          };

          # set up enivronment so that UCM configs are used as well
          environment.variables.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf-asahi}/share/alsa/ucm2";
          systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 =
            config.environment.variables.ALSA_CONFIG_UCM2;
          systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 =
            config.environment.variables.ALSA_CONFIG_UCM2;

          # enable speakersafetyd to protect speakers
          systemd.packages = [ pkgs.speakersafetyd ];
          services.udev.packages = [ pkgs.speakersafetyd ];
        }
      ]
    );
}
