{ inputs, ... }:

{
  flake.nixosModules.pi-coding-agent = { ... }: { };

  flake.homeManagerModules.pi-coding-agent =
    { config, lib, ... }:
    let
      cfg = config.programs.pi-coding-agent;
      agentsFile = "${cfg.contextPath}/AGENTS.md";
    in
    {
      options.programs.pi-coding-agent = {
        enable = lib.mkEnableOption "Pi Coding Agent";
        contextPath = lib.mkOption {
          type = lib.types.path;
          default = inputs.agent-markdown-files;
          description = "Directory whose AGENTS.md becomes pi's global context (~/.pi/agent/AGENTS.md).";
        };
      };

      config = lib.mkIf cfg.enable {
        # pi only reads ~/.pi/agent; linked once the repo has an AGENTS.md
        home.file.".pi/agent/AGENTS.md" = lib.mkIf (builtins.pathExists agentsFile) {
          source = agentsFile;
        };

        programs.zsh.shellAliases = {
          agent = "pi";
        };
      };
    };
}
