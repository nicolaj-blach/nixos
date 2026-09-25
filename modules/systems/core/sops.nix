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

          templates."nix-access-tokens" = {
            owner = metaOwner.username;
            mode = "0400";
            content = ''
              access-tokens = github.com=${config.sops.placeholder.github-token}
            '';
          };
        };

        nix.extraOptions = ''
          !include ${config.sops.templates."nix-access-tokens".path}
        '';
      };
    };
}
