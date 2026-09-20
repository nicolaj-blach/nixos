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
              graph = "log --graph --oneline --decorate";
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

        # Shell aliases (oh-my-zsh git style)
        programs.zsh.shellAliases = {
          # Status
          gst = "git status";
          gss = "git status -s";

          # Add
          ga = "git add";
          gaa = "git add --all";
          gap = "git add --patch";

          # Commit
          gc = "git commit";
          gcm = "git commit -m";
          gca = "git commit --amend";
          gcane = "git commit --amend --no-edit";

          # Push/Pull
          gp = "git push";
          gpf = "git push --force-with-lease";
          gl = "git pull";

          # Diff
          gd = "git diff";
          gds = "git diff --staged";

          # Branch/Checkout/Switch
          gb = "git branch";
          gco = "git checkout";
          gsw = "git switch";
          gswc = "git switch -c";

          # Rebase
          grb = "git rebase";
          grbi = "git rebase -i";
          grbc = "git rebase --continue";
          grba = "git rebase --abort";

          # Restore
          grs = "git restore";
          grss = "git restore --staged";

          # Stash
          gsta = "git stash";
          gstp = "git stash pop";
          gstl = "git stash list";

          # Log
          glog = "git log --oneline";
          glg = "git log --graph --oneline --decorate";
          glast = "git log -1 HEAD --stat";

          # Misc
          gf = "git fetch";
          gm = "git merge";
          gcl = "git clone";
        };
      };
    };
}
