{ ... }:

{
  # MX Master 3S gesture button: tap = niri overview, hold + swipe = workspaces/columns.
  flake.nixosModules.logiops =
    { ... }:
    let
      gesture = direction: keys: {
        inherit direction;
        mode = "OnRelease";
        action = {
          type = "Keypress";
          inherit keys;
        };
      };
    in
    {
      services.logiops = {
        enable = true;
        config.devices = [
          {
            name = "MX Master 3S";
            buttons = [
              {
                cid = 195; # 0xc3, gesture button
                action = {
                  type = "Gestures";
                  gestures = [
                    (gesture "None" [ "KEY_LEFTMETA" "KEY_O" ])
                    (gesture "Up" [ "KEY_LEFTMETA" "KEY_LEFTCTRL" "KEY_J" ])
                    (gesture "Down" [ "KEY_LEFTMETA" "KEY_LEFTCTRL" "KEY_K" ])
                    (gesture "Left" [ "KEY_LEFTMETA" "KEY_L" ])
                    (gesture "Right" [ "KEY_LEFTMETA" "KEY_H" ])
                  ];
                };
              }
            ];
          }
        ];
      };
    };
}
