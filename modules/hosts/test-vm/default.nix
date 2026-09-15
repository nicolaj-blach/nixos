{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosConfigurations.test-vm = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.home-manager.nixosModules.home-manager

      ({ modulesPath, ... }: {
        imports = [
          (modulesPath + "/virtualisation/qemu-vm.nix")
          (modulesPath + "/profiles/qemu-guest.nix")
        ];
      })

      self.nixosModules.personal-computer
      self.nixosModules.test-vm-hardware

      ({ lib, pkgs, ... }: {
        networking.hostName = "test-vm";

        virtualisation = {
          memorySize = 8192;
          cores = 4;
          graphics = true;
          resolution = {
            x = 1920;
            y = 1080;
          };
          qemu.options = [
            "-device virtio-vga-gl"
            "-display gtk,gl=on"
          ];
        };

        services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

        # Don't auto-login to Hyprland - let user choose
        services.displayManager.autoLogin = {
          enable = false;
        };

        # Enable a simple display manager for easier testing
        services.displayManager.sddm.enable = true;
        services.displayManager.sddm.wayland.enable = true;

        users.users.${metaOwner.username} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "video"
            "audio"
          ];
          initialPassword = "test";
        };

        # Auto-login on TTY1 for easier testing
        services.getty.autologinUser = metaOwner.username;

        environment.systemPackages = with pkgs; [
          vim
          htop
          git
          foot
          (writeShellScriptBin "start-hyprland" ''
            echo "Starting Hyprland..."
            exec Hyprland
          '')
          (writeShellScriptBin "test-hm" ''
            echo "Checking Home Manager..."
            if [ -f ~/.hm-test ]; then
              echo "Home Manager is active"
              cat ~/.hm-test
            else
              echo "Home Manager not activated yet"
            fi
            echo ""
            echo "Hyprland config:"
            ls -la ~/.config/hypr/ 2>/dev/null || echo "No hypr config found"
          '')
        ];

        # VM-specific Hyprland environment
        environment.sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
          WLR_RENDERER_ALLOW_SOFTWARE = "1";
        };

        # Add Alt as alternative modifier for VM testing (Super often captured by host)
        home-manager.users.${metaOwner.username} = {
          wayland.windowManager.hyprland.settings = {
            "$altMod" = "ALT";
            bind = [
              "$altMod, RETURN, exec, foot"
              "$altMod, Q, killactive"
              "$altMod, T, exec, foot"
              "$altMod, 1, split-workspace, 1"
              "$altMod, 2, split-workspace, 2"
              "$altMod, 3, split-workspace, 3"
              "$altMod, 4, split-workspace, 4"
              "$altMod, 5, split-workspace, 5"
              "$altMod, LEFT, movefocus, l"
              "$altMod, RIGHT, movefocus, r"
              "$altMod, UP, movefocus, u"
              "$altMod, DOWN, movefocus, d"
            ];
          };

          home.file.".hm-test".text = "Home Manager is working!";
        };
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
