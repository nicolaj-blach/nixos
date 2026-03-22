# Placeholder - replace with output of:
#   sudo nixos-generate-config --show-hardware-config
# Run this on the actual desktop machine after installation
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Replace with actual hardware detection output
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # or kvm-intel for Intel CPU
  boot.extraModulePackages = [ ];

  # TODO: Update with actual UUIDs after installation
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
