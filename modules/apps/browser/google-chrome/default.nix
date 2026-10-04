{ ... }:

{
  flake.homeManagerModules.google-chrome =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.google-chrome ];
    };
}
