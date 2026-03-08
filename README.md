# NixOS Configuration

Single-user, multi-host NixOS flake with LUKS disk encryption, TPM2 auto-unlock, and Secure Boot.

## Installation

Fresh install for Framework 16 laptop (AMD Ryzen 7040/7045).

### Prerequisites

- NixOS live USB (download from https://nixos.org/download)
- Internet connection

### 1. Boot the live USB

Boot from the NixOS minimal ISO. Verify you're in UEFI mode:

```bash
[ -d /sys/firmware/efi/efivars ] && echo "UEFI" || echo "Legacy"
```

### 2. Connect to wifi

```bash
nmcli device wifi connect "SSID" password "PASSWORD"
```

### 3. Partition the disk

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
```

### 4. Set up LUKS encryption

Use `--type luks2` (required for TPM2 enrollment later).

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
```

### 5. Format filesystems

```bash
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
```

### 6. Mount

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

### 7. Generate hardware config and get UUIDs

```bash
nixos-generate-config --root /mnt
```

Get the LUKS partition UUID (this is the UUID of the raw partition, not the mapper):

```bash
blkid /dev/nvme0n1p2
```

Copy the UUID. You'll need it for `hardware-configuration.nix`.

### 8. Clone the repo and update UUIDs

```bash
nix-shell -p git
git clone https://github.com/YOUR_USERNAME/nixos /mnt/home/nixos-config
```

Edit `hosts/personal-laptop/hardware-configuration.nix` and replace the placeholder
UUIDs with the real ones from step 7:

- `boot.initrd.luks.devices."cryptroot".device` -- UUID of `/dev/nvme0n1p2`
- `fileSystems."/boot".device` -- UUID of `/dev/nvme0n1p1`

### 9. Generate Secure Boot keys (before install)

The flake enforces Secure Boot, so keys must exist before installation:

```bash
nixos-enter --root /mnt -c "sbctl create-keys"
```

### 10. Install

```bash
nixos-install --flake /mnt/home/nixos-config#personal-laptop
```

**Note:** This flake uses `mutableUsers = false`, so there is no password prompt.
User passwords are set via `hashedPassword` in the Nix configuration. If you need
to set an initial password, add `initialPassword = "changeme";` to your user config
in `modules/base/user.nix`, then change it after first boot with `passwd`.

### 11. Create UEFI fallback path

Framework laptops (and strict UEFI implementations) may not register NVRAM boot
entries properly. Copy the bootloader to the fallback path so the firmware can
find it:

```bash
nixos-enter --root /mnt
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/limine/limine.efi /boot/EFI/BOOT/BOOTX64.EFI
exit
```

Reboot and remove the USB.

### 12. First boot

You'll be prompted for the LUKS passphrase. Enter it to boot. Log in and clone
the repo to the expected location:

```bash
git clone https://github.com/YOUR_USERNAME/nixos ~/nixos
```

### 13. Set up Secure Boot

Keys were generated in step 9, so skip `sbctl create-keys`. Now enroll them in
the motherboard firmware.

Enter UEFI firmware:

```bash
systemctl reboot --firmware-setup
```

On Framework 16, navigate to Security > Secure Boot and manually delete all keys
from these databases to enter Setup Mode:

- **PK** (Platform Key) - deleting this triggers Setup Mode
- **KEK** (Key Exchange Key) - delete all entries
- **db** (Signature Database) - delete all entries
- **dbt** and **dbr** - delete if present

**Warning:** Do NOT use "Erase all Secure Boot Settings" (firmware bug on some
Framework models). Delete keys individually.

Save (F10) and boot back into NixOS. Verify Setup Mode is active:

```bash
sbctl status  # should show "Setup Mode: Enabled"
```

Enroll your keys:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Rebuild to sign the bootloader:

```bash
nh os switch ~/nixos
```

Verify Secure Boot is active:

```bash
bootctl status  # should show "Secure Boot: enabled (user)"
```

### 14. Enroll TPM2 for auto-unlock

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

### 15. Post-install setup

Stow dotfiles:

```bash
stow -d ~/nixos -t ~ dotfiles
```

## Theming

The system uses [tinted-theming](https://github.com/tinted-theming) for unified
colors across all components. The active scheme is `base16-onedark`.

### Apply a theme

```bash
tinty apply base16-onedark        # One Dark
tinty apply base16-catppuccin-mocha  # Catppuccin Mocha
tinty apply $(tinty list | fzf)   # Pick interactively
```

### List available schemes

```bash
tinty list
```

### How it works

Tinty applies colors to multiple apps via hooks defined in
`dotfiles/.config/tinted-theming/tinty/config.toml`:

- Shell ANSI colors (tinted-shell)
- Ghostty terminal
- fzf
- Hyprland (colors.conf)
- hyprlock
- AGS status bar
- Mako notifications
- Walker launcher

The tinty wrapper in `dotfiles/.zshrc` automatically re-sources shell themes when
you switch. Hyprland and hyprlock colors are generated by custom hook scripts in
`dotfiles/.local/bin/tinty-*-hook`.

## Email

### GPG key (required for AAU OAuth tokens)

Create a GPG key to encrypt OAuth tokens:

```bash
gpg --full-generate-key
```

Follow the prompts (defaults are fine: ECC, Curve 25519, no expiration).

### AAU (Microsoft 365)

Authorize OAuth2 tokens:

```bash
aau-oauth2 --authorize
```

This opens a browser for Microsoft login. After completing login, the tokens are
encrypted with your GPG key.

On first launch after reboot, a pinentry popup will ask for your GPG passphrase.
After entering it once, the passphrase is cached for 30 days.

### Protonmail

First-time setup:

```bash
systemctl --user stop protonmail-bridge
protonmail-bridge -c
```

In the interactive CLI:

1. `login` - enter your Proton credentials
2. `info` - shows IMAP/SMTP credentials for aerc
3. `exit`

Update `~/.config/aerc/accounts.conf` with the credentials from `info`, then start
the background service:

```bash
systemctl --user start protonmail-bridge
```

### Launch aerc

Use `Super+Shift+E` or run `aerc-wrapper` in a terminal.

## Troubleshooting

### No boot option after install

Framework laptops may not register NVRAM boot entries. Boot the live USB and
create the UEFI fallback path:

```bash
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot
nixos-enter
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/limine/limine.efi /boot/EFI/BOOT/BOOTX64.EFI
exit
umount -R /mnt
cryptsetup luksClose cryptroot
reboot
```

### "No sbctl secure boot keys present" during install

The flake requires Secure Boot keys before installing the bootloader. Generate
them before running `nixos-install`:

```bash
nixos-enter --root /mnt -c "sbctl create-keys"
```

If you already installed and hit this error, boot the live USB and:

```bash
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot
nixos-enter
sbctl create-keys
NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/limine/limine.efi /boot/EFI/BOOT/BOOTX64.EFI
exit
```

### Can't log in (no password set)

This flake uses `mutableUsers = false`, so `nixos-install` does not prompt for a
password. Boot the live USB and set an initial password in the config:

```bash
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot
```

Edit `/mnt/home/nixos-config/modules/base/user.nix` and add `initialPassword`:

```nix
users.users.YOUR_USERNAME = {
  initialPassword = "changeme";  # add this line
  # ...
};
```

Then rebuild:

```bash
nixos-enter
nixos-rebuild boot --flake /home/nixos-config#personal-laptop
exit
umount -R /mnt
cryptsetup luksClose cryptroot
reboot
```

After login, change the password with `passwd` and update the config to use
`hashedPassword` instead (generate with `mkpasswd -m sha-512`).

### "Your system is not in Setup Mode"

The motherboard must be in Setup Mode before enrolling Secure Boot keys. Reboot
into BIOS and manually delete all keys from PK, KEK, db, dbt, and dbr. Deleting
the PK triggers Setup Mode.

**Warning:** On Framework laptops, do NOT use "Erase all Secure Boot Settings"
(firmware bug). Delete keys individually.

After clearing keys, boot into NixOS and verify:

```bash
sbctl status  # should show "Setup Mode: Enabled"
```

## Recovery

### TPM refuses to unseal (after BIOS update, Secure Boot key change, etc.)

You'll get a LUKS passphrase prompt. Enter your password, then re-enroll:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
```

### Forgot LUKS passphrase

Use the recovery key from step 14. At the LUKS passphrase prompt, enter the
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

### Reset user password

Boot the live USB, mount, and use `passwd` inside the chroot:

```bash
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount /dev/nvme0n1p1 /mnt/boot
nixos-enter
passwd YOUR_USERNAME
exit
```

**Note:** With `mutableUsers = false`, the password will be reset on next rebuild
unless you update `hashedPassword` in the Nix config.
