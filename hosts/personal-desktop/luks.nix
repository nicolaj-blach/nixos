# LUKS encryption and TPM auto-unlock configuration
# Keep separate from hardware-configuration.nix so it can be regenerated
{ ... }:

{
  boot.initrd.availableKernelModules = [
    "tpm_crb"
    "cryptd"
    "usb_storage"
  ];

  # TODO: Update device name if different from "cryptroot"
  boot.initrd.luks.devices."cryptroot" = {
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];
  };
}
