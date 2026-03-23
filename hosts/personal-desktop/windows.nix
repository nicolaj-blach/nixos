# Windows dual-boot chainload entry for Limine
{ ... }:

{
  boot.loader.limine.extraEntries = ''
    /Windows
        protocol: efi_chainload
        image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
