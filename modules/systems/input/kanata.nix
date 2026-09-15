{ metaOwner, ... }:

{
  flake.nixosModules.kanata =
    { ... }:
    let
      kanataConfig = ''
        (defsrc caps)
        (defalias caps-esc-ctrl (tap-hold 200 200 esc lctl))
        (deflayer base @caps-esc-ctrl)
      '';
    in
    {
      services.kanata = {
        enable = true;
        keyboards.default = {
          config = kanataConfig;
          devices = [ ];
        };
      };

      users.users.${metaOwner.username}.extraGroups = [
        "input"
        "uinput"
      ];
      boot.kernelModules = [ "uinput" ];
      services.udev.extraRules = ''
        KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
      '';
      users.groups.uinput = { };
    };

  flake.homeManagerModules.kanata = { ... }: {
    programs.zsh.shellAliases = {
      kanata-restart = "sudo systemctl restart kanata-default";
      kanata-status = "systemctl status kanata-default";
    };
  };
}
