# configuration that is specific to the ISO
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./installer-configuration.nix
    ../apple-silicon-support
  ];

  # include those modules so the user can rebuild the install iso. that's not
  # especially useful at this point, but the user will need the apple-silicon-support
  # directory for their own config.
  installer.cloneConfigIncludes = [
    "./installer-configuration.nix"
    "./apple-silicon-support"
  ];

  # copy the apple-silicon-support and installer configs into the iso
  boot.postBootCommands = lib.optionalString config.installer.cloneConfig ''
    if ! [ -e /etc/nixos/apple-silicon-support ]; then
      mkdir -p /etc/nixos
      cp ${./installer-configuration.nix} /etc/nixos/installer-configuration.nix
      cp -r ${../apple-silicon-support} /etc/nixos/apple-silicon-support
    fi
  '';
}
