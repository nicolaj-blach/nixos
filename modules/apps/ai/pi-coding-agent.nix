{ inputs, ... }:

{
  flake.nixosModules.pi-coding-agent = { ... }: { };

  flake.homeManagerModules.pi-coding-agent =
    { config, lib, ... }:
    let
      cfg = config.programs.pi-coding-agent;
      markdownFilesPath = inputs.agent-markdown-files;
    in
    {
      options.programs.pi-coding-agent = {
        enable = lib.mkEnableOption "Pi Coding Agent";
        contextPath = lib.mkOption {
          type = lib.types.path;
          default = markdownFilesPath;
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.dataFile."pi-coding-agent/context".source = cfg.contextPath;

        xdg.configFile."pi-coding-agent/config.toml".text = ''
          [context]
          path = "${config.xdg.dataHome}/pi-coding-agent/context"

          [agent]
        '';

        programs.zsh.shellAliases = {
          agent = "pi";
        };
      };
    };
}
