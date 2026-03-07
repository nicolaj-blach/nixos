# NixOS Installation Guide

Fresh install with LUKS disk encryption, TPM2 auto-unlock, Limine bootloader, and Secure Boot.

## Prerequisites

- NixOS live USB (download from https://nixos.org/download)
- Framework 16 laptop (AMD Ryzen 7040/7045)
- Internet connection

## 1. Boot the live USB

Boot from the NixOS minimal ISO. Verify you're in UEFI mode:

```bash
[ -d /sys/firmware/efi/efivars ] && echo "UEFI" || echo "Legacy"
```

## 2. Connect to wifi

```bash
nmcli device wifi connect "SSID" password "PASSWORD"
```

## 3. Partition the disk

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
```

## 4. Set up LUKS encryption

Use `--type luks2` (required for TPM2 enrollment later).

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
```

## 5. Format filesystems

```bash
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
```

## 6. Mount

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

## 7. Generate hardware config and get UUIDs

```bash
nixos-generate-config --root /mnt
```

Get the LUKS partition UUID (this is the UUID of the raw partition, not the mapper):

```bash
blkid /dev/nvme0n1p2
```

Copy the UUID. You'll need it for `hardware-configuration.nix`.

## 8. Clone the repo and update UUIDs

```bash
nix-shell -p git
git clone https://github.com/YOUR_USERNAME/nixos /mnt/home/nixos-config
```

Edit `hosts/personal-laptop/hardware-configuration.nix` and replace the placeholder
UUIDs with the real ones from step 7:

- `boot.initrd.luks.devices."cryptroot".device` -- UUID of `/dev/nvme0n1p2`
- `fileSystems."/boot".device` -- UUID of `/dev/nvme0n1p1`

## 9. Install

```bash
nixos-install --flake /mnt/home/nixos-config#personal-laptop
```

Set a user password when prompted. Reboot and remove the USB.

## 10. First boot

You'll be prompted for the LUKS passphrase. Enter it to boot. Log in and clone
the repo to the expected location:

```bash
git clone https://github.com/YOUR_USERNAME/nixos ~/nixos
```

## 11. Set up Secure Boot

Generate signing keys:

```bash
sudo sbctl create-keys
```

Enter UEFI firmware (reboot, press the firmware key). On the Framework 16, manually
delete all keys from the PK, KEK, and DB sections to enter Setup Mode. Do NOT use
"Erase all Secure Boot Settings" (firmware bug on some Framework models).

Boot back into NixOS and enroll keys:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Secure Boot is now active. Rebuild to sign the bootloader:

```bash
nh os switch ~/nixos
```

Verify:

```bash
bootctl status  # should show "Secure Boot: enabled (user)"
```

## 12. Enroll TPM2 for auto-unlock

This lets the TPM chip unseal the LUKS key automatically so you skip the passphrase
prompt on boot. Only PCR 7 is bound (Secure Boot policy), so hardware swaps on
the Framework 16 (expansion cards, GPU module, etc.) won't cause lockouts.

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

Generate a recovery key and store it somewhere safe (offline, printed, etc.):

```bash
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p2
```

Reboot. The system should auto-unlock without a passphrase.

## 13. Post-install setup

Stow dotfiles:

```bash
stow -d ~/nixos -t ~ dotfiles
```

Re-authorize OAuth2 tokens (old unencrypted tokens won't work with GPG):

```bash
aau-oauth2 --authorize
```

## Recovery

### TPM refuses to unseal (after BIOS update, Secure Boot key change, etc.)

You'll get a LUKS passphrase prompt. Enter your password, then re-enroll:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

### Forgot LUKS passphrase

Use the recovery key from step 12. At the LUKS passphrase prompt, enter the
recovery key string instead.

### Re-installing the bootloader

From a running system:

```bash
sudo nixos-rebuild --install-bootloader boot
```

From a live USB:

```bash
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot
nixos-enter
NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```
