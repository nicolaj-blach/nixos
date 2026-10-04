{ inputs, ... }:

{
  flake.nixosModules.pi-coding-agent = { ... }: { };

  # The pi config itself lives in the pi-config repo; this adds the desktop glue.
  flake.homeManagerModules.pi-coding-agent =
    { config, lib, ... }:
    {
      imports = [ inputs.pi-config.homeManagerModules.default ];

      config = lib.mkIf config.programs.pi-coding-agent.enable {
        pi-config.logo = ../../../../assets/logo.svg;

        # Assistant: continue the last chat, or start a new one
        custom.niri.binds = {
          "Mod+A" = [
            "kitty-popup-assistant"
            "-e"
            "pi-assistant"
            "--continue"
          ];
          "Mod+Shift+A" = [
            "kitty-popup-assistant"
            "-e"
            "pi-assistant"
          ];
        };

        programs.zsh.shellAliases = {
          agent = "pi";
          pic = "pi --continue";
        };
      };
    };
}
