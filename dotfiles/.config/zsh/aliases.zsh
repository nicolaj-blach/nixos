# Shell aliases

# Nix
alias nixu="sudo nix flake update --flake path:$HOME/nixos"
alias nhs="nh search"
alias nixb="nh os build ~/nixos -- --impure"
alias stowd="stow -d ~/nixos -t ~ dotfiles"

# Navigation
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# List
alias ls="eza -lh --group-directories-first --icons=auto"
alias lsa="ls -a"
alias la="ls -lah"
alias lt="eza --tree --level=2 --long --icons --git"
alias lta="lt -a"

# Find
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias ffind="fd --type f | fzf"

# Git (most aliases provided by oh-my-zsh git plugin)
alias lg="lazygit"

# System
alias htop="btop"
alias psg="ps aux | grep"
alias df="df -h"
alias du="du -h"
alias free="free -h"

# Network
alias ping="ping -c 5"
alias wget="wget -c"

# Misc
alias cat="bat --theme=base16-256"
alias clear="clear && fastfetch"
alias please="sudo"

# Bar
alias bar="pkill -9 gjs; sleep 0.5; top-bar & disown"

# AI
alias oc="opencode"
alias occ="opencode -c"
