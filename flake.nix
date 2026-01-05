{
  description = "Apple Silicon support for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      nasImported = import ./. {
        system = "aarch64-linux";
        pkgs = inputs.nixpkgs.legacyPackages."aarch64-linux";
      };
    in
    {
      formatter."aarch64-linux" = nasImported.formatter;
      checks."aarch64-linux" = {
        formatting = outputs.formatter."aarch64-linux";
      };

      overlays = {
        apple-silicon-overlay = nasImported.overlays.apple-silicon-overlay;
        default = outputs.overlays.apple-silicon-overlay;
      };

      nixosModules = {
        apple-silicon-support = nasImported.nixosModules.apple-silicon-support;
        default = outputs.nixosModules.apple-silicon-support;
      };

      packages."aarch64-linux" = {
        inherit (nasImported.packages) linux-asahi uboot-asahi;
        inherit (nasImported) installer-bootstrap;
      };
    };
}
