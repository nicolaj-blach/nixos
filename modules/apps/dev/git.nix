{ metaOwner, ... }:
{
  flake.homeManagerModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.git;
    in
    {
      config = lib.mkIf cfg.enable {
        programs.git = {
          # Use new settings format (replaces userName, userEmail, extraConfig, aliases)
          settings = {
            user = {
              name = metaOwner.fullName;
              email = metaOwner.email;
            };
            init.defaultBranch = "main";
            pull.rebase = true;
            push.autoSetupRemote = true;
            core.editor = "emacsclient -c";
            diff.colorMoved = "default";
            merge.conflictStyle = "diff3";
            alias = {
              st = "status";
              co = "checkout";
              br = "branch";
              ci = "commit";
              lg = "log --graph --oneline --decorate";
            };
          };
        };

        # Delta diff viewer (replaces programs.git.delta)
        programs.delta = {
          enable = true;
          enableGitIntegration = true;
          options = {
            navigate = true;
            light = false;
            side-by-side = true;
            line-numbers = true;
          };
        };

        # GitHub CLI
        programs.gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
            editor = "emacsclient -c";
          };
        };

        # Lazygit
        programs.lazygit.enable = true;
      };
    };
}
