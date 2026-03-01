{ ... }:

{
  programs.zsh.interactiveShellInit = ''
    nixl() {
      nixos-rebuild list-generations 2>/dev/null | awk '
        BEGIN {
          reset  = "\033[0m"
          bold   = "\033[1m"
          blue   = "\033[38;2;97;175;239m"
          green  = "\033[38;2;152;195;121m"
          yellow = "\033[38;2;229;192;123m"
          fg     = "\033[38;2;171;178;191m"
          comment= "\033[38;2;84;88;98m"
          cyan   = "\033[38;2;86;182;194m"

          sep = ""
          for (i = 1; i <= 60; i++) sep = sep "─"
        }
        NR == 1 {
          printf "%s%s  %-4s  %-20s  %s%s\n", blue bold, "Gen", "Date", "Description", reset
          printf "%s%s%s\n", comment, sep, reset
          next
        }
        {
          gen     = $1
          date    = $2
          time    = $3
          version = $4
          current = $NF

          gsub(/_/, " ", version)

          if (current == "True") {
            marker   = yellow "*" reset
            gencolor = yellow bold
          } else {
            marker   = " "
            gencolor = fg
          }

          printf "%s %s%-4s%s  %s%s %s%s  %s%s%s\n", \
            marker, gencolor, gen, reset, \
            cyan, date, time, reset, \
            green, version, reset
        }
      '
    }
  '';
}
