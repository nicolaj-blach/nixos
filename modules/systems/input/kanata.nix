{ metaOwner, ... }:

{
  flake.nixosModules.kanata =
    { ... }:
    let
      # Super+C / Super+V: universal copy/paste (Omarchy-style). Super is released
      # and Ctrl+Insert / Shift+Insert is sent, which works in terminals and GUI apps.
      # With Shift/Ctrl/Alt also held the key passes through (keeps Super+Shift+V).
      kanataConfig = ''
        (defsrc caps lmet rmet c v)

        (defvar
          clip-passthrough (lsft rsft lctl rctl lalt ralt))

        (defalias
          caps-esc-ctrl (tap-hold 200 200 esc lctl)
          sup-l (multi lmet (layer-while-held super))
          sup-r (multi rmet (layer-while-held super))
          copy  (fork (unmod lctl ins) c $clip-passthrough)
          paste (fork (unmod lsft ins) v $clip-passthrough))

        (deflayer base  @caps-esc-ctrl @sup-l @sup-r c v)
        (deflayer super _              _      _      @copy @paste)
      '';
    in
    {
      services.kanata = {
        enable = true;
        keyboards.default = {
          config = kanataConfig;
          # Needed so unmod can track modifiers that are not in defsrc
          extraDefCfg = "process-unmapped-keys yes";
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
