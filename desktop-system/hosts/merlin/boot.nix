{ lib, ... }:
let
  btrfs = [
    "/"
    "/home"
    "/nix"
    "/var/log"
  ];
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.luks.devices.merlin.crypttabExtraOpts = [ "tpm2-device=auto" ];

  fileSystems = lib.genAttrs btrfs (_: {
    options = [
      "compress=zstd"
      "noatime"
    ];
  });
}
