{
  # This project does not use flakes internally, this shim is provided
  # for downstream flake users only.

  # Usage Example
  /*
     nixos-apple-silicon = {
       url = "github:nix-community/nixos-apple-silicon/main";
       inputs.nixpkgs.follows = "nixpkgs";
     };
  */
  description = "Apple Silicon support for NixOS; flake shim";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (self) outputs;
      nasImported = import ./. {
        system = "aarch64-linux";
        pkgs = nixpkgs.legacyPackages."aarch64-linux";
      };
    in
    {
      nixosModules = {
        apple-silicon-support = nasImported.nixosModules.apple-silicon-support;
        default = outputs.nixosModules.apple-silicon-support;
      };

      overlays = {
        apple-silicon-overlay = nasImported.overlays.apple-silicon-overlay;
        default = outputs.overlays.apple-silicon-overlay;
      };

      packages."aarch64-linux" = nasImported.packages;
    };
}
