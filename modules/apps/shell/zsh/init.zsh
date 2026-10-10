# Vi mode config (must be set before oh-my-zsh loads vi-mode plugin)
VI_MODE_SET_CURSOR=true

# zsh-autopair
source @autopair@/share/zsh/zsh-autopair/autopair.zsh

# Secondary prompt
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

# Carapace: multi-shell completion engine
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -d $realpath ]] && eza -1 --color=always --icons=always $realpath || bat -n --color=always $realpath 2>/dev/null'
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# fzf shell integration (CTRL-T, ALT-C keybindings + fuzzy completion; CTRL-R is atuin)
source <(fzf --zsh)

# fzf: completion with fd (faster than default walker)
_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude .git . "$1"
}

# GPG (required for pinentry to work in terminal)
export GPG_TTY=$(tty)

# Inside Emacs (ghostel): open files in the current frame instead of a new one
if [[ -n "$INSIDE_EMACS" ]]; then
  export EDITOR="emacsclient" VISUAL="emacsclient"
fi

# Local overrides (API keys, secrets -- not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
