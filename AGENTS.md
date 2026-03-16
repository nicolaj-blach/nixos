# AGENTS.md

## Overview

Single-user, multi-host NixOS flake. Wayland desktop (Hyprland) on x86_64-linux.
**No home-manager** -- dotfiles are managed via GNU Stow. Do not introduce home-manager.

## Key Commands

| Command | Purpose |
| - | - |
| `nixr feat: desc` | Commit, rebuild (`nh os switch`), push. Rollback on failure. |
| `nh os switch ~/nixos -- --impure` | Rebuild without committing |
| `nh os build ~/nixos` | Dry-run build (check for errors) |
| `statix check .` | Nix linter |
| `stow -d ~/nixos -t ~ dotfiles` | Symlink dotfiles to $HOME |
| `nh search <pkg>` | Search for Nix packages |

There is no test suite. A successful `nh os switch` is the test.
**Use `nh os build ~/nixos` to verify the configuration builds before committing.**

## Constraints

- **No home-manager.** Do not introduce it. Dotfiles are managed via GNU Stow.
- **No hardcoded usernames.** Use the `username` variable from `specialArgs`.
- **No hostname in shared modules.** Set hostname only in `hosts/<name>/default.nix`.
- **No external flake imports in shared modules.** Import them at host level.
- **No hardcoded hex colors in UI.** Use base16 palette variables (see Theming).

## Architecture

- **Golden rule:** NixOS modules provision the machine (hardware, services, binaries).
  Dotfiles personalize the software (preferences, themes, app behavior).
  Shell config (`~/.zshrc`, aliases, scripts) lives in dotfiles, not in Nix modules.
- **Username** is centralized in `flake.nix` via `specialArgs`.
- **Hostname** is set per-host in `hosts/<name>/default.nix`.

### Repository layout

```bash
nixos/
├── flake.nix
├── assets/         # logo/branding files (used by fastfetch)
├── hosts/
│   └── <hostname>/
│       ├── default.nix                 # host-specific config + imports
│       └── hardware-configuration.nix  # auto-generated hardware config
├── modules/
│   ├── base/       # system fundamentals (boot, networking, user, shell, services)
│   ├── desktop/    # Wayland compositor, theming, portals, AGS status bar
│   └── programs/   # packages, app-specific services (protonmail-bridge)
├── src/
│   ├── ags/        # AGS bar source (TypeScript/TSX, built into a Nix derivation)
│   └── scripts/    # Bun TypeScript scripts (nixr, nixl, nixs, yazi-picker, screensaver)
└── dotfiles/       # GNU Stow tree (mirrors $HOME)
```

### Module organization

Shared NixOS modules live under `modules/` in three categories. Each
category has a `default.nix` that re-exports all modules in that
folder, so hosts only import the folder:

| Folder | Purpose | Modules |
| - | - | - |
| `modules/base/` | System fundamentals | `base.nix`, `user.nix`, `shell.nix`, `services.nix` |
| `modules/desktop/` | Desktop environment | `hyprland.nix`, `desktop.nix`, `ags.nix` |
| `modules/programs/` | User apps | `programs.nix`, `protonmail-bridge.nix`, `bit.nix` |

When adding a new module, place the `.nix` file in the appropriate
folder and add it to that folder's `default.nix`. Host configs do not
need to change.

### configModules (specialArgs)

Module paths are passed to hosts via `configModules` in `flake.nix` `specialArgs`.
Hosts import modules by name instead of relative path:

```nix
# In hosts/<name>/default.nix
{ inputs, configModules, ... }:
{
  imports = [
    ./hardware-configuration.nix
    configModules.base
    configModules.desktop
    configModules.programs
  ];
}
```

### src/ directory

`src/` contains source code that gets built into Nix derivations. It
is not part of the Stow-managed dotfiles tree. Generated/vendored
files (`src/ags/@girs/`, `src/scripts/node_modules/`) are gitignored.

## Nix Code Style

- **2 spaces**, no tabs. No trailing whitespace. LF line endings.
- One blank line between the function signature and the opening `{`.
- Module signatures: only destructure what you use, always include `...`.
- Flat dot-path for single settings; nested attrset for 2+ related settings.
- `with pkgs;` only scoped to list context, never at module level.
- `let` bindings use `camelCase`. `in` goes on its own line before `{`.
- Multi-line shell strings use `''...''`. Shell `$vars` are not escaped.
- Comments: `#` (hash + space). Use as section headers in package lists.
- No `/* */` block comments.

## Commit Messages

Format: `<type>: <description>`

Types: `feat:`, `fix:`, `refactor:`. Lowercase, past tense, no period, single line.

## Dotfiles / GNU Stow

`dotfiles/` mirrors `$HOME`. Run `stow -d ~/nixos -t ~ dotfiles` to
symlink into `~`.
Place app configs at `dotfiles/.config/<app>/`.
Shell scripts go in `dotfiles/.local/bin/` with `#!/usr/bin/env bash`.

## Theming (Tinty / Base16)

System-wide colors are managed by **Tinty** (tinted-theming). The
active scheme is `base16-onedark`. Always respect and integrate with
this theme system.

### How it works

- Config: `dotfiles/.config/tinted-theming/tinty/config.toml`
- `tinty apply <scheme>` applies a base16 scheme to all configured apps at once.
- Custom hooks in `dotfiles/.local/bin/tinty-*-hook` generate
  app-specific color files.

### Base16 color mapping

| Base16 slot | Role | Usage |
| - | - | - |
| `base00` | Background | Panel backgrounds, shadow |
| `base01` | Lighter background | Inactive borders |
| `base02` | Selection | Borders, separators, muted UI elements |
| `base03` | Comments | Secondary text (dates, prompts, status lines) |
| `base05` | Foreground | Primary text (time, headings) |
| `base08` | Red | Errors, destructive actions |
| `base0D` | Blue | Primary accent (active borders) |
| `base0E` | Purple | Secondary accent (titles, highlights) |

### Guidelines

- **Never hardcode hex colors.** Use base16 palette variables from tinty hooks.
- **Hyprland colors** are defined as variables (`$active_border_1`, `$inactive_border`,
  etc.) in generated `~/.config/hypr/colors.conf`. Use these in Hyprland configs.
- **New apps:** Add a `[[items]]` entry to tinty's `config.toml`, or write a custom
  hook in `dotfiles/.local/bin/tinty-<app>-hook`.
- **Generated files stay out of git.** Tinty hooks overwrite files at runtime.

### UI design principles

- **Sharp corners.** No rounded corners (`rounding = 0`).
- **Monospace font.** JetBrainsMono Nerd Font for all UI text.
- **Minimal chrome.** Single-pixel borders, no gradients, no shadows on widgets.
- **No animations.** Fade-in/fade-out disabled for instant transitions.
