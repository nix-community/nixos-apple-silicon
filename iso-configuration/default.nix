{
  self,
  system,
  pkgs,
}:
import (pkgs.path + "/nixos/lib/eval-config.nix") {
  inherit system;
  specialArgs = {
    modulesPath = pkgs.path + "/nixos/modules";
  };
  modules = [
    self.nixosModules.apple-silicon-support
    ./installer-configuration.nix
    {
      hardware.asahi.pkgsSystem = system;
      nixpkgs.hostPlatform.system = "aarch64-linux";
      nixpkgs.buildPlatform.system = system;
      nixpkgs.overlays = [ self.overlays.apple-silicon-overlay ];
    }
  ];
}
