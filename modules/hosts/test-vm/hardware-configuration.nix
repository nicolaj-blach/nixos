{ ... }:

{
  flake.nixosModules.test-vm-hardware = { lib, ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.limine.enable = false;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
      "virtio_blk"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    swapDevices = [ ];

    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
