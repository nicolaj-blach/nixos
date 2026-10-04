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

        home.packages = [ pkgs.devenv ];

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

        # Define use_devenv function for direnv
        xdg.configFile."direnv/lib/use_devenv.sh".text = ''
          # use_devenv - activate a devenv environment
          # Usage in .envrc: use devenv
          use_devenv() {
            watch_file devenv.nix
            watch_file devenv.lock
            watch_file devenv.yaml
            watch_file .devenv.flake.nix

            # Check if devenv is available
            if ! command -v devenv &> /dev/null; then
              log_error "devenv is not installed. Install it with: nix profile install nixpkgs#devenv"
              return 1
            fi

            # Use devenv's built-in direnv integration
            eval "$(devenv print-dev-env --impure)"
          }
        '';
      };
    };
}
