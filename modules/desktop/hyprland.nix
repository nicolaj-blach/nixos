{
  pkgs,
  inputs,
  username,
  ...
}:

{
  # Create local.conf for host-specific Hyprland config if it doesn't exist
  system.activationScripts.hyprLocalConf = ''
        dir="/home/${username}/.config/hypr"
        file="$dir/local.conf"
        if [ ! -f "$file" ]; then
          mkdir -p "$dir"
          chown ${username}:users "$dir"
          cat > "$file" << 'EOF'
    # Host-specific Hyprland configuration
    # This file is auto-created but not managed by NixOS - edit freely

    # Monitor configuration (create this file for custom multi-monitor setups)
    # source = ~/.config/hypr/monitors.conf
    EOF
          chown ${username}:users "$file"
        fi
  '';

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    };

    hyprlock.enable = true;

    # Requires inputs.walker.nixosModules.default to be imported at the host level
    walker.enable = true;
  };

  # Load split-monitor-workspaces plugin at startup
  environment.systemPackages = [
    inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
  ];

  security.pam.services.hyprlock.nodelay = true;
}
