{
  # Fractal Adjust Pro web app access to Fractal devices
  flake.nixosModules.fractal = {
    services.udev.extraRules = ''
      SUBSYSTEMS=="usb*", ATTRS{idVendor}=="36bc", MODE="0660", GROUP="users"
    '';
  };
}
