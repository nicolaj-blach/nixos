{ ... }:
{
  flake.homeManagerModules.atuin =
    {
      lib,
      unstablePkgs,
      ...
    }:
    {
      # atuin: Ctrl+R history search (Up stays on history-substring-search)
      programs.atuin = {
        enable = true;
        # 18.21 for Atuin AI (? on an empty prompt) and pty-proxy
        package = unstablePkgs.atuin;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          # Turned on in systems/ai; atuin enables it when unset
          ai.enabled = lib.mkDefault false;
          auto_sync = false;
          update_check = false;
          style = "compact";
          inline_height = 15;
          show_preview = true;
          enter_accept = false;
          keymap_mode = "vim-insert";
          filter_mode = "global";
          search_mode = "fuzzy";
          history_filter = [
            "^ls$"
            "^cd$"
            "^clear$"
            "^fe$"
          ];
          theme.name = "onedark";
        };
        themes.onedark = {
          theme.name = "onedark";
          colors = {
            Base = "#abb2bf";
            Title = "#61afef";
            Important = "#61afef";
            Guidance = "#c678dd";
            Annotation = "#5c6370";
            Muted = "#5c6370";
            AlertInfo = "#98c379";
            AlertWarn = "#e5c07b";
            AlertError = "#e06c75";
          };
        };
      };

      # Run last so atuin, not fzf, owns Ctrl+R in every keymap
      programs.zsh.initContent = lib.mkOrder 2000 ''
        bindkey -M emacs '^r' atuin-search
        bindkey -M viins '^r' atuin-search-viins
        bindkey -M vicmd '^r' atuin-search-vicmd
      '';
    };
}
