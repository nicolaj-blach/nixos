{ ... }:
{
  flake.homeManagerModules.devenv =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.devenv;
    in
    {
      options.programs.devenv = {
        enable = lib.mkEnableOption "devenv with direnv integration";
      };

      config = lib.mkIf cfg.enable {
        # Direnv for automatic environment activation
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          config = {
            global = {
              warn_timeout = "1m";
              hide_env_diff = true;
            };
          };
        };

        # Add devenv to user packages (system package is also available)
        home.packages = [ pkgs.devenv ];

        # Shell integration for direnv
        programs.zsh.initContent = lib.mkAfter ''
          # Devenv/direnv hook (if not already loaded by programs.direnv)
          if command -v direnv &> /dev/null; then
            eval "$(direnv hook zsh)"
          fi
        '';

        programs.bash.initExtra = lib.mkAfter ''
          # Devenv/direnv hook (if not already loaded by programs.direnv)
          if command -v direnv &> /dev/null; then
            eval "$(direnv hook bash)"
          fi
        '';

        # Useful aliases for devenv
        home.shellAliases = {
          de = "devenv";
          des = "devenv shell";
          deu = "devenv up";
          det = "devenv test";
          dei = "devenv init";
          dec = "devenv container";
        };

        # Add devenv to allowed direnv directories (for nix-direnv caching)
        xdg.configFile."direnv/direnv.toml".text = ''
          [global]
          warn_timeout = "1m"
          hide_env_diff = true

          [whitelist]
          prefix = [
            "~/projects",
            "~/code",
            "~/src",
            "~/work"
          ]
        '';
      };
    };
}
