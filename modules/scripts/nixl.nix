{ ... }:

{
  programs.zsh.interactiveShellInit = ''
    nixl() {
      nixos-rebuild list-generations 2>/dev/null | awk '
        BEGIN {
          reset = "\033[0m"
          bold  = "\033[1m"
          blue  = "\033[34m"
          green = "\033[32m"
          yellow= "\033[33m"
          cyan  = "\033[36m"

          printf "%s  %-4s  %-20s  %s\n", blue bold, "Gen", "Date", "Description" reset
        }
        NR > 1 && NF > 0 {
          gen     = $1
          version = $4
          current = $NF
          gsub(/_/, " ", version)

          marker   = (current == "True") ? yellow "*" reset : " "
          gencolor = (current == "True") ? yellow bold : ""

          printf "%s %s%-4s%s  %s%s %s%s  %s%s%s\n", \
            marker, gencolor, gen, reset, \
            cyan, $2, $3, reset, \
            green, version, reset
        }
      '
    }
  '';
}
