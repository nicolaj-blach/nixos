{ ... }:

{
  boot.initrd.availableKernelModules = [
    "tpm_crb"
    "cryptd"
    "usb_storage"
  ];

  boot.initrd.luks.devices."cryptroot" = {
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];
  };
}
