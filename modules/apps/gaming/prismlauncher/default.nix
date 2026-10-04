{ ... }:

{
  flake.homeManagerModules.prismlauncher =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.prismlauncher ];
    };
}
