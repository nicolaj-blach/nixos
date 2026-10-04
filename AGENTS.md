# NixOS configuration

Nicolaj Blach Jensen's NixOS flake (`nicolaj-blach`, me@nicolaj-blach.dev). Everything about the machines is declared here. Branch `modix-config`, remote `github.com/nicolaj-blach/nixos`.

## How I want you to work
- Short, clear explanations. Ask when something is unclear instead of guessing.
- Everything managed in Nix. Keep comments minimal: only where the code can't explain itself.
- Prefer `nixpkgs` (stable, `nixos-25.11`), fall back to `nixpkgs-unstable`.
- Simple over clever: the smallest change that works, no speculative options or abstractions. If a solution grows large, stop and look for one that uses what a tool already provides.
- Never run `sudo`, `nixos-rebuild` or `home-manager switch`. I rebuild myself with `sudo nixos-rebuild switch --flake ~/nixos#personal-desktop`.
- Never commit or push unless I ask. Commits are signed automatically.

## Layout
flake-parts with import-tree: every `.nix` file under `modules/` is imported automatically. Folders starting with `_` (`_hw`, `_files`, `_hm-module.nix`, ...) are skipped; put non-module files there. Each file defines `flake.nixosModules.<name>` and/or `flake.homeManagerModules.<name>`; a module only takes effect once a configuration or host imports it.

`flake.nix` passes `inputs`, `metaOwner` (username, full name, email), `secretsRoot` and `hasSecrets` to every module.

### `modules/apps/` — user-facing applications
GUIs, TUIs and CLIs. Each app has its own folder and defines everything about that app in one place:
- the package and its configuration
- keybindings that open it (niri binds)
- shell aliases and functions
- its theme (OneDark Pro)
- window rules, desktop entries, MIME defaults, popups

Adding, changing or removing an app should only touch its folder (plus the import in a configuration).

### `modules/systems/` — parts of a configuration
Boot, audio, networking, the desktop session, secrets, the AI gateway, and so on. Each system is as self-contained as possible: it brings its own options, services and packages and doesn't reach into other systems.

### `modules/configurations/` — use cases
A configuration describes a kind of machine, like a personal computer or a server, by importing systems and apps. Today: `personal-computer`.

### `modules/hosts/` — one machine each
A host imports exactly one configuration, plus its hardware configuration and anything specific to that machine. Example: the laptop uses `personal-computer` but also enables its fingerprint reader.
- `personal-desktop`: this machine. Ryzen 5 7600X, NVIDIA GTX 1080 drives all three monitors (the AMD iGPU is unused). Monitors left to right: HDMI-A-2 AOC 1920x1080, DP-2 Lenovo 3440x1440, DP-3 Samsung 1680x1050 rotated.
- `personal-labtop`: laptop with an AMD GPU.
- `test-vm`: a VM, CPU only.

### Separate repos
When a part grows into its own project or is useful outside this config, suggest moving it to its own repo and importing it as a flake input. Existing examples:
- `quickshell-bar` (`~/quickshell-bar`): the top bar, configured here through `services.quickshell-bar`.
- `agent-markdown-files` (`~/projects/personal/agent-markdown-files`): `AGENTS.md`, `assistant.md`, agents and skills for coding agents.
- `secrets`: a git submodule at `secrets/`, encrypted with sops.

After changing one of these repos: commit, push, then `nix flake update <input>` here.

## My desktop
- **niri** (Wayland compositor), quickshell-bar, hyprlock, swayosd, mako, swww wallpaper.
- **Terminal: ghostel inside Doom Emacs** (with evil). Ghostel is an Emacs terminal built on libghostty; it is *not* the Ghostty terminal emulator, even though it reports `TERM=xterm-ghostty`. Inside it `INSIDE_EMACS=ghostel` is set, and evil owns `Esc` (`evil-ghostel-escape 'evil`).
- **kitty** is the secondary terminal, used mainly for popups: fsel, otter-launcher, wlctl, bluetui, wiremix, qalc, the pi assistant. Popup classes: `popup`, `popup-term` (700x500), `popup-large` and `popup-assistant` (1200x750).
- zsh with oh-my-zsh, starship, atuin (Ctrl+R), fzf, zoxide, carapace.
- Launchers: otter-launcher (`Mod+Space`) and fsel (`Mod+Escape` is the system menu). Browser: Zen (`zen-beta`). File manager: superfile; yazi is the file picker.
- Look: OneDark Pro everywhere (`#282c34` background, `#abb2bf` text, `#61afef` blue, `#98c379` green, `#e06c75` red, `#e5c07b` yellow, `#c678dd` purple), sharp corners, JetBrainsMono Nerd Font. Everything US: language and keyboard layout.

## Coding agents and AI
- `modules/systems/ai`: ollama (Vulkan by default; CUDA/ROCm selectable), LiteLLM gateway on `127.0.0.1:4000` (`openrouter/*`, `ollama/*`), atuin-ai-server on `127.0.0.1:8080`. The `ai-models` service rebuilds the model lists for atuin, opencode and pi at boot and hourly.
- `modules/apps/ai/pi`: pi from `llm-agents.nix`, configured through Home Manager's `programs.pi-coding-agent` (vendored in `_hm-module.nix` until the HM release has it). `~/.pi/agent` is read-only; extensions are pinned `npm:` packages in `settings.packages`.

## Verify every change
1. New files are invisible to the flake until `git add`-ed.
2. Build: `nix build --no-link --print-out-paths '.#nixosConfigurations.personal-desktop.config.system.build.toplevel'`
3. Read the generated files you changed: find `home-manager-files` in `nix-store -qR <result>`.
4. niri config: `niri validate -c <generated config.kdl>`.
5. Other hosts: `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` for `personal-labtop` and `test-vm`.
6. Then tell me what to run and what to check after the rebuild.

## Gotchas
- **"Would be clobbered":** Home Manager refuses to replace files it didn't create. Before I rebuild, check whether a real file already sits where a new link goes, and move it aside (`<file>.pre-hm`).
- Apps that write their own config on first run (atuin, superfile) recreate those files if run before the rebuild.
- Sandboxed apps (Steam, Bazecor) die with their parent; launch them through `niri msg action spawn --`.
- superfile only starts if `config.toml` and `hotkeys.toml` contain every field.
- Secrets: `secrets/*.yaml` via sops-nix (`modules/systems/core/sops.nix`). Only the desktop is a sops recipient. Never print or decrypt secrets.
- The edit tool can't match Nerd Font glyphs; use a script for edits that contain them. In Nix strings, `''${` escapes shell interpolation.
