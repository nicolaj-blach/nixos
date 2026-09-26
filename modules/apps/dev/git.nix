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
      tokenFile = "/run/secrets/github-token";
      signingKeyFile = "/run/secrets/git-signing-key";
      signingPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMnwYqEcTBV1umwmhTgwYld+W9eavk0DGgu2S/96v8BO";
      allowedSigners = pkgs.writeText "git-allowed-signers" ''
        ${metaOwner.email} ${signingPubKey}
      '';

      github-credential = pkgs.writeShellScript "git-credential-github-sops" ''
        if [ -r ${tokenFile} ]; then
          [ "$1" = get ] || exit 0
          echo "username=${metaOwner.username}"
          echo "password=$(cat ${tokenFile})"
        else
          exec ${config.programs.gh.package}/bin/gh auth git-credential "$@"
        fi
      '';
    in
    {
      config = lib.mkIf cfg.enable {
        programs.git = {
          ignores = [
            ".direnv/"
            ".devenv/"
            ".devenv.flake.nix"
            ".devenv*"
            "devenv.nix"
            "devenv.yaml"
            "devenv.lock"
            "devenv.local.nix"
            ".envrc"
          ];

          # Use new settings format (replaces userName, userEmail, extraConfig, aliases)
          settings = {
            user = {
              name = metaOwner.fullName;
              email = metaOwner.email;
              signingKey = signingKeyFile;
            };
            gpg.format = "ssh";
            gpg.ssh.allowedSignersFile = "${allowedSigners}";
            commit.gpgSign = true;
            tag.gpgSign = true;
            init.defaultBranch = "main";
            pull.rebase = true;
            push.autoSetupRemote = true;
            diff.colorMoved = "default";
            merge.conflictStyle = "diff3";
            alias = {
              graph = "log --graph --oneline --decorate";
            };
            credential."https://github.com".helper = [
              ""
              "${github-credential}"
            ];
            credential."https://gist.github.com".helper = [
              ""
              "${github-credential}"
            ];
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
          gitCredentialHelper.enable = false;
          settings = {
            git_protocol = "https";
          };
        };

        programs.zsh.initContent = ''
          [[ -r ${tokenFile} ]] && export GH_TOKEN="$(< ${tokenFile})"
        '';

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
          gswca = "git switch canary";
          gswma = "git switch main";
          gswms = "git switch master";
          gsws = "git switch staging";
          gswp = "git switch production";

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
          glfp = "git log --first-parent --oneline --decorate";

          # Misc
          gf = "git fetch";
          gm = "git merge";
          gcl = "git clone";
        };
      };
    };
}
