{ ... }:

{
  flake.homeManagerModules.ghostty =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ghostty ];
    };
}
