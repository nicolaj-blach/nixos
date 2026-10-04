{ ... }:

{
  flake.homeManagerModules.chromium =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.chromium ];
    };
}
