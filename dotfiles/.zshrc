# ~/.zshrc - Shell personalization (sourced for interactive shells)
# NixOS handles /etc/zshrc (history, completion, keybindings).
# This file handles oh-my-zsh, plugins, prompt, and personal preferences.

# Vi mode config (must be set before oh-my-zsh loads vi-mode plugin)
VI_MODE_SET_CURSOR=true
KEYTIMEOUT=1

# Oh-my-zsh
export ZSH="/run/current-system/sw/share/oh-my-zsh"
plugins=(
  git
  sudo
  vi-mode
  history-substring-search
  colored-man-pages
  extract
  command-not-found
)

if [[ ! -d "$HOME/.cache/oh-my-zsh" ]]; then
  mkdir -p "$HOME/.cache/oh-my-zsh"
fi
ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"

source "$ZSH/oh-my-zsh.sh"

# External plugins (sourced after oh-my-zsh)
source /run/current-system/sw/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /run/current-system/sw/share/zsh-autopair/autopair.zsh

# Prompt
eval "$(starship init zsh)"
PROMPT2="    "

# Shift+Enter inserts newline without executing
insert-newline() { LBUFFER+=$'\n'; }
zle -N insert-newline
bindkey '^[[13;2u' insert-newline

# Reset to insert mode on every new prompt
__reset_vi_mode() { zle vi-insert 2>/dev/null; }
if [[ -z "${widgets[zle-line-init]+x}" ]]; then
  zle -N zle-line-init __reset_vi_mode
else
  __orig_line_init="${widgets[zle-line-init]#user:}"
  function zle-line-init() {
    "${__orig_line_init}" 2>/dev/null
    zle vi-insert 2>/dev/null
  }
  zle -N zle-line-init
fi

# Transient prompt: redraw current prompt without vi indicator on Enter
function zle-line-finish() {
  __saved_prompt="$PROMPT"
  PROMPT=$' \e[1;32m>\e[0m '
  zle reset-prompt
  PROMPT="$__saved_prompt"
}
zle -N zle-line-finish

# Zoxide
eval "$(zoxide init zsh)"

# fzf shell integration (CTRL-T, CTRL-R, ALT-C keybindings + fuzzy completion)
source <(fzf --zsh)

# fzf: use fd as default source (respects .gitignore, faster than find)
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

# fzf: CTRL-T (paste files/directories onto command-line)
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,.direnv
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# fzf: ALT-C (cd into directory)
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.direnv
  --preview 'eza --tree --level=2 --icons --color=always {}'"

# fzf: CTRL-R (search command history)
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
  --color header:italic
  --header 'CTRL-Y to copy command to clipboard'"

# fzf: completion with fd (faster than default walker)
_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude .git . "$1"
}

# Tinty: source shell theme on init and wrap apply/cycle to re-source
tinty_source_shell_theme() {
  local tinty_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
  while read -r script; do
    [[ -f "$script" ]] && source "$script"
  done < <(find "$tinty_data_dir" -maxdepth 1 -type f -name "*.sh" 2>/dev/null)
}

tinty() {
  command tinty "$@"
  local subcommand="$1"
  if [[ "$subcommand" == "apply" || "$subcommand" == "init" || "$subcommand" == "cycle" ]]; then
    tinty_source_shell_theme
  fi
}

tinty_source_shell_theme

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# nix-ld: make libraries available to dynamically-linked binaries (numpy, etc.)
export LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib"

# GPG (required for pinentry to work in terminal)
export GPG_TTY=$(tty)

# Aliases
source "$HOME/.config/zsh/aliases.zsh"

# Local overrides (API keys, secrets -- not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
