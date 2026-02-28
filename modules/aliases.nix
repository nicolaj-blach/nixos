{ username, ... }:

{
  programs.zsh.shellAliases = {
    # Nix
    nixu = "sudo nix flake update /home/${username}/nixos";
    nixl = "nixos-rebuild list-generations";
    nhs = "nh search";
    nixb = "nh os build ~/nixos -- --impure";
    stowd = "stow -d ~/nixos -t ~ dotfiles";

    # Navigation
    cd = "z";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";

    # List
    ls = "eza -lh --group-directories-first --icons=auto";
    lsa = "ls -a";
    la = "ls -lah";
    lt = "eza --tree --level=2 --long --icons --git";
    lta = "lt -a";

    # Find
    ff = "fzf --preview 'bat --style=numbers --color=always {}'";
    ffind = "fd --type f | fzf";

    # Git
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gd = "git diff";
    gco = "git checkout";
    gb = "git branch";
    gss = "git status -s";
    lg = "lazygit";

    # System
    htop = "btop";
    psg = "ps aux | grep";
    df = "df -h";
    du = "du -h";
    free = "free -h";

    # Network
    ping = "ping -c 5";
    wget = "wget -c";

    # Misc
    cat = "bat --theme=base16-256";
    clear = "clear && fastfetch";
    please = "sudo";

    # AI
    oc = "opencode";
    occ = "opencode -c";
  };
}
