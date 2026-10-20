{ ... }:

{
  flake.homeManagerModules.proton-pass =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      ...
    }:
    let
      # The kernel keyring is unusable here (no session keyring under greetd/systemd),
      # so the local key lives in tmpfs instead: wiped on reboot, log in once per boot.
      # 2.2+ is needed for `pass-cli session create-lock`.
      pass-cli = pkgs.writeShellScriptBin "pass-cli" ''
        key="$XDG_RUNTIME_DIR/proton-pass.key"
        if [ ! -s "$key" ]; then
          (umask 077; head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1 > "$key")
          # A session encrypted with the previous boot's key can't be read anymore
          rm -rf "''${XDG_DATA_HOME:-$HOME/.local/share}/proton-pass-cli/.session"
        fi
        PROTON_PASS_KEY_PROVIDER=env PROTON_PASS_ENCRYPTION_KEY=$(cat "$key") \
          exec ${unstablePkgs.proton-pass-cli}/bin/pass-cli "$@"
      '';
    in
    {
      options.programs.proton-pass.enable = lib.mkEnableOption "Proton Pass CLI";

      config = lib.mkIf config.programs.proton-pass.enable {
        home.packages = [ pass-cli ];
      };
    };
}
