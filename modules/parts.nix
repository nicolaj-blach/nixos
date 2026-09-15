{ inputs, lib, ... }:

{
  options.flake = {
    homeManagerModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };

  config = {
    systems = [ "x86_64-linux" ];

    perSystem = { system, ... }: {
      _module.args = {
        unstablePkgs = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
  };
}
