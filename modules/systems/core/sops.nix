{
  inputs,
  secretsRoot,
  hasSecrets,
  metaOwner,
  ...
}:

{
  flake.nixosModules.sops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      sopsPkgs = unstable.callPackage inputs.sops-nix { };
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      config = lib.mkIf hasSecrets {
        sops = {
          package = sopsPkgs.sops-install-secrets;
          validationPackage = sopsPkgs.sops-install-secrets;
          defaultSopsFile = secretsRoot + "/github.yaml";
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

          secrets.github-token = {
            owner = metaOwner.username;
            mode = "0400";
          };

          secrets.git-signing-key = {
            owner = metaOwner.username;
            mode = "0400";
          };

          secrets.ai-gateway-token = {
            sopsFile = secretsRoot + "/aiModels.yaml";
            owner = metaOwner.username;
            mode = "0400";
          };

          secrets.openrouter-api-key = {
            sopsFile = secretsRoot + "/aiModels.yaml";
          };

          # Shared by LiteLLM and atuin-ai-server
          templates."ai-gateway.env".content = ''
            OPENROUTER_API_KEY=${config.sops.placeholder.openrouter-api-key}
            AUTH_TOKEN=${config.sops.placeholder.ai-gateway-token}
          '';

          templates."nix-access-tokens" = {
            owner = metaOwner.username;
            mode = "0400";
            content = ''
              access-tokens = github.com=${config.sops.placeholder.github-token}
            '';
          };
        };

        environment.systemPackages = with pkgs; [
          sops
          age
          ssh-to-age
        ];

        nix.extraOptions = ''
          !include ${config.sops.templates."nix-access-tokens".path}
        '';
      };
    };
}
