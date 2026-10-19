{ ... }:
{
  flake.homeManagerModules.devenv =
    {
      config,
      lib,
      unstablePkgs,
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

        home.packages = [ unstablePkgs.devenv ];

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
