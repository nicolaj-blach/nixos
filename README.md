# NixOS Configuration

<!--toc:start-->
- [NixOS Configuration](#nixos-configuration)
  - [What's Included](#whats-included)
  - [Repository Structure](#repository-structure)
    - [Module organization](#module-organization)
  - [Daily Usage](#daily-usage)
    - [Nix commands](#nix-commands)
    - [AI commands](#ai-commands)
    - [Keybindings (Hyprland)](#keybindings-hyprland)
  - [Adding a New Host](#adding-a-new-host)
  - [Theming](#theming)
    - [Apply a theme](#apply-a-theme)
    - [List available schemes](#list-available-schemes)
    - [How it works](#how-it-works)
  - [Email](#email)
    - [AAU (Microsoft 365)](#aau-microsoft-365)
    - [Protonmail](#protonmail)
    - [Launch aerc](#launch-aerc)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [1. Boot the live USB](#1-boot-the-live-usb)
    - [2. Connect to wifi (if needed)](#2-connect-to-wifi-if-needed)
    - [3. Identify your disk](#3-identify-your-disk)
    - [4. Partition the disk](#4-partition-the-disk)
    - [5. Set up LUKS encryption](#5-set-up-luks-encryption)
    - [6. Format filesystems](#6-format-filesystems)
    - [7. Mount](#7-mount)
    - [8. Generate hardware config and get UUIDs](#8-generate-hardware-config-and-get-uuids)
    - [9. Clone the repo and create host config](#9-clone-the-repo-and-create-host-config)
    - [10. Generate Secure Boot keys (before install)](#10-generate-secure-boot-keys-before-install)
    - [11. Install](#11-install)
    - [12. Create UEFI fallback path (if needed)](#12-create-uefi-fallback-path-if-needed)
    - [13. First boot](#13-first-boot)
    - [14. Set up Secure Boot](#14-set-up-secure-boot)
    - [15. Enroll TPM2 for auto-unlock](#15-enroll-tpm2-for-auto-unlock)
    - [16. Post-install setup](#16-post-install-setup)
  - [Troubleshooting](#troubleshooting)
    - [No boot option after install](#no-boot-option-after-install)
    - ["No sbctl secure boot keys present" during install](#no-sbctl-secure-boot-keys-present-during-install)
    - [Can't log in (no password set)](#cant-log-in-no-password-set)
    - ["Your system is not in Setup Mode"](#your-system-is-not-in-setup-mode)
  - [Recovery](#recovery)
    - [TPM refuses to unseal (after BIOS update, Secure Boot key change, etc.)](#tpm-refuses-to-unseal-after-bios-update-secure-boot-key-change-etc)
    - [Forgot LUKS passphrase](#forgot-luks-passphrase)
    - [Re-installing the bootloader](#re-installing-the-bootloader)
    - [Reset user password](#reset-user-password)
<!--toc:end-->

Single-user, multi-host NixOS flake with LUKS disk encryption, TPM2
auto-unlock, and Secure Boot.

## What's Included

This flake provides a complete Wayland desktop environment:

- **Compositor:** Hyprland with hyprlock screen locker
- **Status bar:** AGS (Aylur's GTK Shell)
- **Launcher:** Walker
- **Terminal:** Ghostty
- **Notifications:** Mako
- **Theming:** Tinted-theming (base16) with system-wide color management
- **Security:** LUKS encryption, TPM2 auto-unlock, Secure Boot
  (sbctl/Lanzaboote)
- **Boot:** Plymouth splash screen, Limine bootloader

Dotfiles are managed separately via GNU Stow (no home-manager).

## Repository Structure

```text
nixos/
├── flake.nix               # Flake definition, host declarations
├── hosts/
│   └── <hostname>/
│       ├── default.nix                 # Host-specific config
│       └── hardware-configuration.nix  # Auto-generated hardware config
├── modules/
│   ├── base/       # System fundamentals (boot, networking, user, shell)
│   ├── desktop/    # Wayland compositor, theming, AGS status bar
│   └── programs/   # Packages, app-specific services
├── src/
│   ├── ags/        # AGS bar source (TypeScript)
│   └── scripts/    # Helper scripts (nixr, etc.)
└── dotfiles/       # GNU Stow tree (mirrors $HOME)
```

### Module organization

| Folder | Purpose |
| - | - |
| `modules/base/` | Boot, networking, user accounts, shell, services |
| `modules/desktop/` | Hyprland, desktop portals, AGS |
| `modules/programs/` | User applications, protonmail-bridge |

Host configs import modules via `configModules` from `specialArgs`:

```nix
imports = [
  configModules.base
  configModules.desktop
  configModules.programs
];
```

## Daily Usage

### Nix commands

| Command | Purpose |
| - | - |
| `nixr <msg>` | Commit, rebuild, push, stow (rollback on failure) |
| `nixl` | List NixOS generations with descriptions |
| `nixs` | Switch to a previous generation (fzf picker) |
| `nixu` | Update flake inputs |
| `nixb` | Dry-run build (check for errors) |
| `nhs <pkg>` | Search for Nix packages |
| `ns <pkgs...>` | Temporary nix shell (e.g., `ns cowsay figlet`) |
| `stowd` | Symlink dotfiles to $HOME |

### AI commands

| Command | Purpose |
| - | - |
| `an <prompt>` | Start a new LLM conversation |
| `a <prompt>` | Continue the current LLM conversation |
| `ac` | Select a previous conversation to continue (fzf picker) |
| `oc` | Launch OpenCode |
| `occ` | Launch OpenCode in compact mode |

### Keybindings (Hyprland)

See `dotfiles/.config/hypr/binds.conf` for the full list. Navigation uses vim keys
(h/j/k/l). Common bindings:

| Key | Action |
| `Super + Return` | Terminal |
| `Super + Space` | Launcher (Walker) |
| `Super + W` | Close window |
| `Super + B` | Browser |
| `Super + D` | Discord (Vesktop) |
| `Super + Shift + E` | Email (aerc) |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |

## Adding a New Host

1. Create `hosts/HOSTNAME/` with `default.nix` and `hardware-configuration.nix`
2. Add the host to `flake.nix` under `nixosConfigurations`
3. Generate `hardware-configuration.nix` on the target machine:

   ```bash
   nixos-generate-config --show-hardware-config > hosts/HOSTNAME/hardware-configuration.nix
   ```

Host-specific settings (hostname, hardware quirks) go in the host's `default.nix`.
Shared configuration lives in `modules/`.

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

### AAU (Microsoft 365)

Authorize OAuth2 tokens:

```bash
aau-oauth2 --authorize
```

This opens a browser for Microsoft login. After completing login, tokens are
stored in `~/.local/share/aerc/aau-tokens`.

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

Use `Super+Shift+E` or run `aerc` in a terminal.

## Installation

Fresh install for any x86_64-linux machine.

### Prerequisites

- NixOS live USB (download from <https://nixos.org/download>)
- Internet connection

### 1. Boot the live USB

Boot from the NixOS minimal ISO. Verify you're in UEFI mode:

```bash
[ -d /sys/firmware/efi/efivars ] && echo "UEFI" || echo "Legacy"
```

### 2. Connect to wifi (if needed)

```bash
nmcli device wifi connect "SSID" password "PASSWORD"
```

### 3. Identify your disk

```bash
lsblk
```

Note your target disk (e.g., `/dev/nvme0n1`, `/dev/sda`). Replace `$DISK` in the
following commands with your actual disk path.

### 4. Partition the disk

```bash
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%
```

This creates:

- Partition 1: 512MB EFI System Partition
- Partition 2: Remainder for LUKS-encrypted root

### 5. Set up LUKS encryption

Use `--type luks2` (required for TPM2 enrollment later).

```bash
cryptsetup luksFormat --type luks2 ${DISK}p2   # or ${DISK}2 for SATA
cryptsetup luksOpen ${DISK}p2 cryptroot
```

### 6. Format filesystems

```bash
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mkfs.fat -F 32 -n BOOT ${DISK}p1
```

### 7. Mount

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount ${DISK}p1 /mnt/boot
```

### 8. Generate hardware config and get UUIDs

```bash
nixos-generate-config --root /mnt
```

Get the LUKS partition UUID (this is the UUID of the raw partition, not the mapper):

```bash
blkid ${DISK}p2
```

Copy the UUID. You'll need it for `hardware-configuration.nix`.

### 9. Clone the repo and create host config

```bash
nix-shell -p git
git clone https://github.com/YOUR_USERNAME/nixos /mnt/home/nixos-config
```

Create a new host directory (replace `HOSTNAME` with your machine name):

```bash
mkdir -p /mnt/home/nixos-config/hosts/HOSTNAME
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/nixos-config/hosts/HOSTNAME/
```

Create `hosts/HOSTNAME/default.nix`:

```nix
{ inputs, configModules, ... }:

{
  networking.hostName = "HOSTNAME";

  imports = [
    ./hardware-configuration.nix
    configModules.base
    configModules.desktop
    configModules.programs
    inputs.walker.nixosModules.default
  ];
}
```

Edit `hardware-configuration.nix` and update the LUKS device UUID from step 8.

Add the new host to `flake.nix` (copy the existing host block and change the name).

### 10. Generate Secure Boot keys (before install)

The flake enforces Secure Boot, so keys must exist before installation:

```bash
nixos-enter --root /mnt -c "sbctl create-keys"
```

### 11. Install

```bash
nixos-install --flake /mnt/home/nixos-config#HOSTNAME
```

**Note:** This flake uses `mutableUsers = false`, so there is no password prompt.
User passwords are set via `hashedPassword` in the Nix configuration. If you need
to set an initial password, add `initialPassword = "changeme";` to your user config
in `modules/base/user.nix`, then change it after first boot with `passwd`.

### 12. Create UEFI fallback path (if needed)

Some UEFI implementations don't register NVRAM boot entries properly. If your
machine fails to boot after install, copy the bootloader to the fallback path:

```bash
nixos-enter --root /mnt
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/limine/limine.efi /boot/EFI/BOOT/BOOTX64.EFI
exit
```

Reboot and remove the USB.

### 13. First boot

You'll be prompted for the LUKS passphrase. Enter it to boot. Log in and clone
the repo to the expected location:

```bash
git clone https://github.com/YOUR_USERNAME/nixos ~/nixos
```

### 14. Set up Secure Boot

Keys were generated in step 10, so skip `sbctl create-keys`. Now enroll them in
the motherboard firmware.

Enter UEFI firmware:

```bash
systemctl reboot --firmware-setup
```

Navigate to Security > Secure Boot and enter Setup Mode by deleting all keys from:

- **PK** (Platform Key) - deleting this triggers Setup Mode
- **KEK** (Key Exchange Key) - delete all entries
- **db** (Signature Database) - delete all entries
- **dbt** and **dbr** - delete if present

**Note:** Some firmware has an "Erase all Secure Boot Settings" option that may
not work correctly. If in doubt, delete keys individually.

Save and boot back into NixOS. Verify Setup Mode is active:

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

### 15. Enroll TPM2 for auto-unlock

This lets the TPM chip unseal the LUKS key automatically so you skip the passphrase
prompt on boot. Only PCR 7 is bound (Secure Boot policy).

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 ${DISK}p2
```

Generate a recovery key and store it somewhere safe (offline, printed, etc.):

```bash
sudo systemd-cryptenroll --recovery-key ${DISK}p2
```

Reboot. The system should auto-unlock without a passphrase.

### 16. Post-install setup

Stow dotfiles:

```bash
stow -d ~/nixos -t ~ dotfiles
```

## Troubleshooting

### No boot option after install

Some UEFI firmware doesn't register NVRAM boot entries. Boot the live USB and
create the UEFI fallback path:

```bash
cryptsetup luksOpen ${DISK}p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount ${DISK}p1 /mnt/boot
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
cryptsetup luksOpen ${DISK}p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount ${DISK}p1 /mnt/boot
nixos-enter
sbctl create-keys
NIXOS_INSTALL_BOOTLOADER=1 \
  /nix/var/nix/profiles/system/bin/switch-to-configuration boot
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/limine/limine.efi /boot/EFI/BOOT/BOOTX64.EFI
exit
```

### Can't log in (no password set)

This flake uses `mutableUsers = false`, so `nixos-install` does not prompt for a
password. Boot the live USB and set an initial password in the config:

```bash
cryptsetup luksOpen ${DISK}p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount ${DISK}p1 /mnt/boot
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
nixos-rebuild boot --flake /home/nixos-config#HOSTNAME
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

After clearing keys, boot into NixOS and verify:

```bash
sbctl status  # should show "Setup Mode: Enabled"
```

## Recovery

### TPM refuses to unseal (after BIOS update, Secure Boot key change, etc.)

You'll get a LUKS passphrase prompt. Enter your password, then re-enroll:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 ${DISK}p2
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 ${DISK}p2
```

### Forgot LUKS passphrase

Use the recovery key generated during installation (step 15). At the LUKS
passphrase prompt, enter the recovery key string instead.

### Re-installing the bootloader

From a running system:

```bash
sudo nixos-rebuild --install-bootloader boot
```

From a live USB:

```bash
cryptsetup luksOpen ${DISK}p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount ${DISK}p1 /mnt/boot
nixos-enter
NIXOS_INSTALL_BOOTLOADER=1 \
  /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```

### Reset user password

Boot the live USB, mount, and use `passwd` inside the chroot:

```bash
cryptsetup luksOpen ${DISK}p2 cryptroot
mount /dev/mapper/cryptroot /mnt
mount ${DISK}p1 /mnt/boot
nixos-enter
passwd YOUR_USERNAME
exit
```

**Note:** With `mutableUsers = false`, the password will be reset on next rebuild
unless you update `hashedPassword` in the Nix config.
