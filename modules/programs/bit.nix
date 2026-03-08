{
  pkgs,
  ...
}:

let
  bit = pkgs.buildGoModule rec {
    pname = "bit";
    version = "0.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "superstarryeyes";
      repo = "bit";
      rev = "v${version}";
      hash = "sha256-iLwWKn8csoRkr5H8R2kpZVZCxsL0LDWHNvNoxyM6y98=";
    };

    vendorHash = "sha256-Zxw0NyZfM42ytn+vDExLwRgNLWsdGVLC3iNVpQd8VMw=";

    subPackages = [ "cmd/bit" ];

    meta = {
      description = "CLI/TUI Logo Designer + ANSI Font Library";
      homepage = "https://github.com/superstarryeyes/bit";
      license = pkgs.lib.licenses.mit;
      mainProgram = "bit";
    };
  };
in
{
  environment.systemPackages = [ bit ];
}
