{ ... }:

{
  flake.homeManagerModules.xdg-dirs =
    { config, pkgs, ... }:
    let
      home = config.home.homeDirectory;
      templates = "${home}/templates";

      # tpl            list templates
      # tpl <name>     copy a template file, or the contents of a template folder, into .
      tpl = pkgs.writeShellScriptBin "tpl" ''
        dir="${templates}"
        if [ -z "$1" ]; then
          ${pkgs.eza}/bin/eza --tree --icons=always --level=2 "$dir"
          exit 0
        fi
        src="$dir/$1"
        if [ -d "$src" ]; then
          cp -rLn --no-preserve=mode "$src"/. .
        elif [ -e "$src" ]; then
          cp -Ln --no-preserve=mode "$src" "''${2:-.}"
        else
          echo "tpl: no template '$1' in $dir" >&2
          exit 1
        fi
      '';
    in
    {
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        download = "${home}/downloads";
        documents = "${home}/documents";
        pictures = "${home}/media/pictures";
        videos = "${home}/media/videos";
        music = "${home}/media/music";
        templates = templates;
        desktop = home;
        publicShare = home;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${home}/media/pictures/screenshots";
        };
      };

      home.activation.createExtraHomeDirs = config.lib.dag.entryAfter [ "linkGeneration" ] ''
        run mkdir -p $VERBOSE_ARG \
          "${home}/notes" "${home}/projects" "${home}/media/pictures/screenshots"
      '';

      home.file."templates/devenv/devenv.nix".text = ''
        { pkgs, ... }:

        {
          packages = [ pkgs.git ];

          enterShell = '''
            echo "devenv ready"
          ''';
        }
      '';
      home.file."templates/devenv/devenv.yaml".text = ''
        inputs:
          nixpkgs:
            url: github:cachix/devenv-nixpkgs/rolling
      '';
      home.file."templates/devenv/.envrc".text = ''
        use devenv
      '';

      home.packages = [ tpl ];
    };
}
