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
| `cat`   | `bat`                                                 |
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
