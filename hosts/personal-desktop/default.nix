{
  inputs,
  configModules,
  config,
  pkgs,
  ...
}:

{
  networking.hostName = "personal-desktop";

  imports = [
    ./hardware-configuration.nix
    ./luks.nix
    ./windows.nix
    configModules.base
    configModules.desktop
    configModules.programs
  ];

  # NVIDIA proprietary drivers for gaming (desktop only)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  # Force NVIDIA EGL for OpenGL apps (fixes FreeCAD, Blender, etc.)
  environment.sessionVariables = {
    __EGL_VENDOR_LIBRARY_FILENAMES = "${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
