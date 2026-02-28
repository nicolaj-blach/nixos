{ username, ... }:

{
  services.getty.autologinUser = username;

  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;
}
