# Atuin AI: ? on an empty prompt (atuin only binds it in the emacs keymap)
(( ${+widgets[self-atuin-ai-question-mark]} )) && bindkey -M viins '?' self-atuin-ai-question-mark

# Token for the local AI gateway (atuin-ai-server, litellm-proxy)
if [[ -r /run/secrets/ai-gateway-token ]]; then
  export ATUIN_AI__API_TOKEN="$(< /run/secrets/ai-gateway-token)"
  export LITELLM_PROXY_API_KEY="$ATUIN_AI__API_TOKEN"
fi

# Atuin AI model chosen with `aim` (ai-model); re-read before every prompt
if (( $+commands[ai-model] )); then
  alias aim=ai-model
  alias aiu=ai-usage
  _atuin_ai_model() {
    local f="${XDG_STATE_HOME:-$HOME/.local/state}/atuin/ai-model"
    if [[ -s $f ]]; then
      export ATUIN_AI__MODEL="$(< $f)"
    else
      unset ATUIN_AI__MODEL
    fi
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _atuin_ai_model
  _atuin_ai_model

  # Refresh every tool's model list after the local models change
  ollama() {
    command ollama "$@" || return
    case $1 in
      pull|rm|cp|create) ai-refresh &! ;;
    esac
  }
fi
