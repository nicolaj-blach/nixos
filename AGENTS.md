# AGENTS.md

## Overview

Single-user, multi-host NixOS flake. Wayland desktop (Hyprland) on x86_64-linux.
**No home-manager** -- dotfiles are managed via GNU Stow. Do not introduce home-manager.

## Build / Switch Commands

```bash
nixr "feat: description"        # commit -> nh os switch -> push (rollback on failure)
nh os switch ~/nixos -- --impure # rebuild without committing
nh os build ~/nixos -- --impure  # dry-run build (check for errors)
statix check .                   # nix linter
```

There is no test suite. A successful `nh os switch` is the test.

## Aliases (defined in modules/shell.nix)

| Alias   | Expands to                                            |
|---------|-------------------------------------------------------|
| `nixr`  | function: commit + `nh os switch` + push              |
| `nixu`  | `sudo nix flake update ~/nixos`                       |
| `nixl`  | `nixos-rebuild list-generations`                      |
| `nhs`   | `nh search`                                           |
| `stowd` | `stow -t ~ ~/nixos/dotfiles`                          |
| `ls`    | `eza -lh --group-directories-first --icons=auto`      |
| `lsa`   | `ls -a`                                               |
| `la`    | `ls -lah`                                             |
| `lt`    | `eza --tree --level=2 --long --icons --git`           |
| `cat`   | `bat --theme=base16-256`                              |
| `cd`    | `z` (zoxide)                                          |
| `gs`    | `git status`                                          |
| `ga`    | `git add`                                             |
| `gc`    | `git commit`                                          |
| `gp`    | `git push`                                            |
| `gl`    | `git pull`                                            |
| `gd`    | `git diff`                                            |
| `lg`    | `lazygit`                                             |
| `oc`    | `opencode`                                            |

## Architecture

- **No home-manager.** Dotfiles live in `dotfiles/` and are symlinked via `stow`.
- **Username** is centralized in `flake.nix` via `specialArgs`. Never hardcode it.
- **Hostname** is set per-host in `hosts/<name>/default.nix`, not in shared modules.
- **External flake modules** are imported at the host level, not inside shared modules.

## Nix Code Style

- **2 spaces**, no tabs. No trailing whitespace. LF line endings.
- One blank line between the function signature and the opening `{`.
- Module signatures: only destructure what you use, always include `...`.
- Flat dot-path for single settings; nested attrset for 2+ related settings.
- `with pkgs;` only scoped to list context, never at module level.
- `let` bindings use `camelCase`. `in` goes on its own line before `{`.
- Multi-line shell strings use `''...''`. Shell `$vars` are not escaped.
- Comments: `# ` (hash + space). Use as section headers in package lists.
- No `/* */` block comments.

## Commit Messages

Format: `<type>: <description>`

Types: `feat:`, `fix:`, `refactor:`. Lowercase, past tense, no period, single line.

## Dotfiles / GNU Stow

`dotfiles/` mirrors `$HOME`. Run `stowd` to symlink everything into `~`.
Place app configs at `dotfiles/.config/<app>/`.
Shell scripts go in `dotfiles/.local/bin/` with `#!/usr/bin/env bash`.

## Theming (Tinty / Base16)

System-wide colors are managed by **Tinty** (tinted-theming). The active scheme is
`base16-onedark`. Always respect and integrate with this theme system.

### How it works

- Config: `dotfiles/.config/tinted-theming/tinty/config.toml`
- `tinty apply <scheme>` applies a base16 scheme to all configured apps at once.
- `tinty init` reapplies the last-used scheme (runs on shell init and Hyprland autostart).
- Shell integration in `modules/shell.nix` wraps `tinty` so that `apply`/`init`/`cycle`
  automatically re-source shell-based themes (ANSI colors, fzf).

### Themed apps

| App | Method | Notes |
|-----|--------|-------|
| **Shell (ANSI)** | `tinted-shell` | Sourced via tinty shell wrapper |
| **Ghostty** | `tinted-terminal` | Hook copies to `~/.config/ghostty/colors` |
| **fzf** | `tinted-fzf` | Sourced via tinty shell wrapper |
| **Hyprland** | Custom hook script | `~/.local/bin/tinty-hyprland-hook` generates `~/.config/hypr/colors.conf` |
| **bat** | Alias | `bat --theme=base16-256` in shell aliases |
| **Neovim** | `navarasu/onedark.nvim` | Dedicated plugin, `transparent = true` (uses terminal bg) |

### Guidelines

- **Prefer themed options.** When adding CLI tools or aliases, use base16-aware themes
  when available (e.g. `bat --theme=base16-256`, fzf inherits from `tinted-fzf`).
- **New apps:** If a tinted-theming template exists, add an `[[items]]` entry to
  `config.toml`. If not, check if the app supports importing a color file and write a
  custom hook in `dotfiles/.local/bin/`.
- **Neovim is separate.** It uses a dedicated onedark.nvim plugin instead of base16-vim
  because base16's 16-color mapping doesn't look good with treesitter/LSP highlights.
  If the base16 scheme changes, update `colorscheme.lua` to match.
- **Hyprland colors** are defined as variables (`$active_border_1`, `$active_border_2`,
  `$inactive_border`, `$shadow_color`) in the generated `colors.conf`. Use these
  variables in Hyprland configs instead of hardcoding rgba values.
- **Generated files stay out of git.** Tinty hooks write to `~/.config/ghostty/colors`
  and `~/.config/hypr/colors.conf` (replaces Stow symlink at runtime). The dotfiles repo
  ships seed defaults for first-boot only.

### Switching themes

```bash
tinty apply base16-catppuccin-mocha   # switch everything
tinty apply $(tinty list | fzf)       # pick interactively
tinty list                            # see all 250+ schemes
```
