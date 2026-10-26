# NixOS configuration

Nicolaj Blach Jensen's NixOS flake (`nicolaj-blach`, me@nicolaj-blach.dev). Everything about the machines is declared here. Branch `modix-config`, remote `github.com/nicolaj-blach/nixos`.

## How I want you to work
- Short, clear explanations. Ask when something is unclear instead of guessing.
- Everything managed in Nix. Keep comments minimal: only where the code can't explain itself.
- Prefer `nixpkgs` (stable, `nixos-26.05`), fall back to `nixpkgs-unstable` through the `unstablePkgs` module argument (NixOS and Home Manager). Unfree packages are allowed in both.
- Simple over clever: the smallest change that works, no speculative options or abstractions. If a solution grows large, stop and look for one that uses what a tool already provides.
- Never run `sudo`, `nixos-rebuild` or `home-manager switch`. I rebuild myself with `sudo nixos-rebuild switch --flake ~/setup/nixos#personal-desktop`.
- Never commit or push unless I ask. Commits are signed automatically.

## Layout
flake-parts with import-tree: every `.nix` file under `modules/` is imported automatically. Folders starting with `_` (`_hw`, `_files`, `_hm-module.nix`, ...) are skipped; put non-module files there. Each file defines `flake.nixosModules.<name>` and/or `flake.homeManagerModules.<name>`; a module only takes effect once a configuration or host imports it.

`flake.nix` passes `inputs`, `metaOwner` (username, full name, email), `secretsRoot` and `hasSecrets` to every module.

### `modules/apps/` — user-facing applications
One folder per app: `modules/apps/<category>/<app>/default.nix`, with extra files (patches, assets) next to it. Categories describe what the app is for: `ai`, `browser`, `dev`, `editor`, `files`, `gaming`, `launcher`, `productivity`, `settings`, `shell`, `socials`, `terminal`. Never split them by GUI, TUI or CLI: wlctl and a GUI wifi app would both go in `settings/`. Files shared by several apps in a category go in `_`-prefixed files (`files/_dir-icons.nix`).

Each app defines everything about itself in its folder:
- the package and its configuration
- keybindings that open it (`custom.niri.binds`)
- shell aliases and functions
- its theme (OneDark Pro)
- window rules (`custom.niri.extraConfig`), startup commands (`custom.niri.startup`), desktop entries, MIME defaults, popups

Adding, changing or removing an app should only touch its folder (plus the import in a configuration).

The niri module (`systems/desktop/niri/home.nix`) renders `custom.niri.{binds,startup,environment,extraConfig}` into one `config.kdl`. A bind is `"Mod+B" = [ "zen-beta" ];` (spawn) or `"Mod+W" = "close-window;";` (action). Two modules binding the same key is an eval error.

### `modules/systems/` — parts of a configuration
Boot, audio, networking, the desktop session, secrets, the AI gateway, and so on. Each system is as self-contained as possible: it brings its own options, services and packages and doesn't reach into other systems.

### `modules/configurations/` — use cases
A configuration describes a kind of machine, like a personal computer or a server, by importing systems and apps. Today: `personal-computer`.

### `modules/hosts/` — one machine each
A host imports exactly one configuration, plus its hardware configuration (`_hw/hardware-configuration.nix`) and anything specific to that machine. Example: the laptop uses `personal-computer` but also enables its fingerprint reader.
- `personal-desktop`: this machine. Ryzen 5 7600X, NVIDIA GTX 1080 drives all three monitors (the AMD iGPU is unused). Monitors left to right: HDMI-A-2 AOC 1920x1080, DP-2 Lenovo 3440x1440, DP-3 Samsung 1680x1050 rotated. The NVIDIA niri workarounds live in this host.
- `personal-laptop`: laptop with an AMD GPU.

### Separate repos
When a part grows into its own project or is useful outside this config, suggest moving it to its own repo and importing it as a flake input. Existing examples:
- `quickshell-bar` (`~/setup/quickshell-bar`): the top bar, configured here through `services.quickshell-bar`.
- `agent-markdown-files` (`~/setup/agent-markdown-files`): `AGENTS.md`, `assistant.md`, agents and skills for coding agents.
- `pi-config` (`~/setup/pi-config`): pi's Home Manager module. It takes `agent-markdown-files` and `llm-agents` as its own inputs; update them with `nix flake update pi-config/agent-markdown-files` here.
- `secrets`: a git submodule at `secrets/`, encrypted with sops.

After changing one of these repos: commit, push, then `nix flake update <input>` here.

## My desktop
- **niri** (Wayland compositor), quickshell-bar, hyprlock, swayosd, mako, awww wallpaper.
- **Terminal: ghostel inside Doom Emacs** (with evil). Ghostel is an Emacs terminal built on libghostty; it is *not* the Ghostty terminal emulator, even though it reports `TERM=xterm-ghostty`. Inside it `INSIDE_EMACS=ghostel` is set, and evil owns `Esc` (`evil-ghostel-escape 'evil`).
- **kitty** is the secondary terminal, used mainly for popups: fsel, otter-launcher, wlctl, bluetui, wiremix, qalc, the pi assistant. Popup classes: `popup`, `popup-term` (700x500), `popup-large` and `popup-assistant` (1200x750).
- zsh with oh-my-zsh, starship, atuin (Ctrl+R), fzf, zoxide, carapace.
- Launchers: otter-launcher (`Mod+Space`) and fsel (`Mod+Escape` is the system menu). Browser: Zen (`zen-beta`); Chromium and Google Chrome are also installed. File manager: superfile; yazi is the file picker.
- Look: OneDark Pro everywhere (`#282c34` background, `#abb2bf` text, `#61afef` blue, `#98c379` green, `#e06c75` red, `#e5c07b` yellow, `#c678dd` purple), sharp corners, JetBrainsMono Nerd Font. Everything US: language and keyboard layout.

## Coding agents and AI
- `modules/systems/ai`: ollama (Vulkan by default; CUDA/ROCm selectable), LiteLLM gateway on `127.0.0.1:4000` (`openrouter/*`, `ollama/*`), atuin-ai-server on `127.0.0.1:8080`. The `ai-models` service rebuilds the model lists for atuin, opencode and pi at boot and hourly.
- `modules/apps/ai/pi`: imports the `pi-config` input and adds the desktop glue (niri binds, zsh aliases, logo). Everything else about pi (wrapper, settings, pinned `npm:` packages, theme, permissions) is in the `pi-config` repo. `~/.pi/agent` is read-only.

## Verify every change
1. New files are invisible to the flake until `git add`-ed.
2. Build: `nix build --no-link --print-out-paths '.#nixosConfigurations.personal-desktop.config.system.build.toplevel'`
3. Read the generated files you changed: find `home-manager-files` in `nix-store -qR <result>`.
4. niri config: `niri validate -c <generated config.kdl>`.
5. Laptop: `nix eval --raw .#nixosConfigurations.personal-laptop.config.system.build.toplevel.drvPath`.
6. Then tell me what to run and what to check after the rebuild.

## Pending reminders
When you finish a task in this repo, add one short line at the end of your reply for each item below that is still open. Don't bring it up otherwise and don't act on it unasked.
- **niri runs unreleased main** (input `niri-src`, override in `modules/systems/desktop/niri/default.nix`) for multi-monitor portal screenshots, which flameshot needs (niri commit `ee8a04b`, 2026-09-18). Once a niri release after 26.04 is in `nixpkgs-unstable` (`nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.niri.version'`), remind me: switch to `package = unstablePkgs.niri;`, drop the `niri-src` input and remove this item.

## Gotchas
- **"Would be clobbered":** Home Manager refuses to replace files it didn't create. Before I rebuild, check whether a real file already sits where a new link goes, and move it aside (`<file>.pre-hm`).
- Apps that write their own config on first run (atuin, superfile) recreate those files if run before the rebuild.
- Sandboxed apps (Steam, Bazecor) die with their parent; launch them through `niri msg action spawn --`.
- superfile only starts if `config.toml` and `hotkeys.toml` contain every field.
- Secrets: `secrets/*.yaml` via sops-nix (`modules/systems/core/sops.nix`). Both the desktop and the laptop are sops recipients (`secrets/.sops.yaml`). Never print or decrypt secrets.
- The edit tool can't match Nerd Font glyphs; use a script for edits that contain them. In Nix strings, `''${` escapes shell interpolation.
