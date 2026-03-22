# Windows dual-boot chainload entry for Limine
{ ... }:

{
  boot.loader.limine.extraEntries = ''
    /Windows
        PROTOCOL=efi_chainload
        IMAGE_PATH=boot():/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
