# ai-models (service), ai-refresh, ai-model and ai-usage
{
  pkgs,
  lib,
  cfg,
  ports,
  stateDir,
  tokenFile,
  localContext,
}:
let
  # Refreshes the cached model lists and writes every tool's model config
  aiModels = pkgs.writeShellApplication {
    name = "ai-models";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
      diffutils
      systemd
    ];
    text = ''
      cd ${stateDir}

      # Replace a cached list only on a successful download, keeping the old one otherwise
      fetch() {
        if curl -fsS "''${@:2}" > "$1.new"; then
          mv "$1.new" "$1"
        else
          rm -f "$1.new"
          echo "Couldn't refresh $1, using the cached copy" >&2
        fi
        [ -s "$1" ] || echo '{}' > "$1"
        chmod 0644 "$1"
      }
      fetch openrouter.json --max-time 20 https://openrouter.ai/api/v1/models
      fetch ollama.json --max-time 10 --retry 10 --retry-connrefused --retry-delay 2 \
        http://127.0.0.1:${toString ports.ollama}/api/tags

      # Add each pulled model's capabilities (tools, vision, ...) from /api/show
      jq -r '.models // [] | .[] | select(has("capabilities") | not) | .name' ollama.json \
        | while read -r m; do
            curl -fsS --max-time 10 http://127.0.0.1:${toString ports.ollama}/api/show \
              -d "$(jq -cn --arg m "$m" '{ model: $m }')" \
              | jq -c --arg m "$m" '{ ($m): (.capabilities // []) }' \
              || jq -cn --arg m "$m" '{ ($m): [] }'
          done \
        | jq -s 'add // {}' > caps.json
      jq --slurpfile caps caps.json \
        '.models |= ((. // []) | map(.capabilities = (.capabilities // $caps[0][.name] // [])))' ollama.json \
        > ollama.json.new && mv ollama.json.new ollama.json
      chmod 0644 ollama.json
      rm -f caps.json

      # Declared local models are listed even while they're still downloading
      jq -n --argjson declared ${lib.escapeShellArg (builtins.toJSON cfg.models)} \
        --slurpfile ol ollama.json --slurpfile or openrouter.json \
        --argjson localContext ${toString localContext} \
        --from-file ${./models.jq} > models.json

      default=$(jq -r --arg d ${lib.escapeShellArg cfg.defaultModel} \
        'if any(.[]; .alias == $d) then $d else .[0].alias end' models.json)

      # Write to a temp file and rename, so readers never see a half-written file
      publish() { cat > "$1.new" && chmod 0644 "$1.new" && mv "$1.new" "$1"; }

      {
        echo 'port = ${toString ports.atuin}'
        echo 'endpoint = "http://127.0.0.1:${toString ports.gateway}/v1"'
        echo 'api_key = { env = "AUTH_TOKEN" }'
        jq -rn --arg d "$default" '"default_model = \($d | tojson)"'
        printf '\n[request.body]\nstream_options = { include_usage = true }\n'
        jq -r '.[] | "\n[[models]]",
          (({ alias, name, description, model: .alias } | to_entries[]) | "\(.key) = \(.value | tojson)")' models.json
      } > atuin.toml.next

      # atuin-ai-server only reads its model list at start: restart it when the list changed.
      # try-restart skips a stopped server (boot, ai-refresh); --no-block avoids waiting on
      # a server that is itself ordered after this service.
      if cmp -s atuin.toml.next atuin.toml; then
        rm atuin.toml.next
      else
        publish atuin.toml < atuin.toml.next
        rm atuin.toml.next
        echo "Model list changed, restarting atuin-ai-server"
        systemctl --no-block try-restart podman-atuin-ai-server.service
      fi

      # opencode: merged into its own config via OPENCODE_CONFIG
      jq '{
        "$schema": "https://opencode.ai/config.json",
        provider: { litellm: {
          npm: "@ai-sdk/openai-compatible",
          name: "LiteLLM (local gateway)",
          options: { baseURL: "http://127.0.0.1:${toString ports.gateway}/v1",
                     apiKey: "{file:${tokenFile}}" },
          models: (map({ key: .alias, value: {
            name: (if .local then "\(.name) (local)" else .name end),
            tool_call: true,
            reasoning: (.reasoning // false),
            attachment: (.input | index("image") != null),
            modalities: { input: .input, output: ["text"] },
            limit: { context: .context, output: .output },
            cost: { input: .cost.input, output: .cost.output,
                    cache_read: .cost.cacheRead, cache_write: .cost.cacheWrite } } })
            | from_entries) } } }' models.json | publish opencode.json

      # pi: linked to ~/.pi/agent/models.json
      jq '{ providers: { litellm: {
        baseUrl: "http://127.0.0.1:${toString ports.gateway}/v1",
        api: "openai-completions",
        apiKey: "!cat ${tokenFile}",
        compat: { supportsDeveloperRole: false },
        models: map({
          id: .alias,
          name: (if .local then "\(.name) (local)" else .name end),
          reasoning: (.reasoning // false),
          input: .input,
          contextWindow: .context,
          maxTokens: .output,
          cost: .cost }) } } }' models.json | publish pi-models.json

      echo "ai-models: $(jq length models.json) models, default $default"
      rm -f models.json
    '';
  };

  aiRefresh = pkgs.writeShellApplication {
    name = "ai-refresh";
    runtimeInputs = with pkgs; [
      systemd
      libnotify
      gnugrep
    ];
    text = ''
      if systemctl restart ai-models.service podman-atuin-ai-server.service; then
        n=$(grep -c '^\[\[models\]\]' ${stateDir}/atuin.toml || true)
        notify-send -a "AI" "AI models refreshed" "$n models available"
      else
        notify-send -u critical -a "AI" "AI refresh failed" "journalctl -u ai-models -u podman-atuin-ai-server"
        exit 1
      fi
    '';
  };

  aiModel = pkgs.writeShellApplication {
    name = "ai-model";
    runtimeInputs = with pkgs; [
      curl
      jq
      fzf
      coreutils
      gnused
    ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/atuin/ai-model"

      if [ "''${1:-}" = "--reset" ]; then
        rm -f "$state"
        echo "AI model: server default"
        exit 0
      fi

      token_file=/run/secrets/ai-gateway-token
      [ -r "$token_file" ] || { echo "ai-model: can't read $token_file" >&2; exit 1; }

      srv=$(curl -fsS --max-time 10 -H "Authorization: Bearer $(cat "$token_file")" \
        http://127.0.0.1:${toString ports.atuin}/api/cli/models) \
        || { echo "ai-model: AI server not reachable (try ai-refresh)" >&2; exit 1; }

      default=$(jq -r .default <<< "$srv")
      cur=$(cat "$state" 2>/dev/null || true)
      cur=''${cur:-$default}

      # Cached by atuin-ai-models on server start; no prices until the first refresh
      or=${stateDir}/openrouter.json
      ol=${stateDir}/ollama.json
      [ -r "$or" ] || or=/dev/null
      [ -r "$ol" ] || ol=/dev/null

      choice=$(jq -rn --arg cur "$cur" --argjson srv "[$srv]" \
          --slurpfile or "$or" --slurpfile ol "$ol" \
          --from-file ${./model-rows.jq} \
        | fzf --delimiter $'\t' --with-nth 2 --accept-nth 1 \
            --header "AI model: $cur   (price = \$ per 1M tokens in / out)" \
            --header-first --layout reverse --height 80% \
            --preview 'echo {3} | sed "s/\\\\n/\n/g"' --preview-window 'right,45%,wrap') \
        || exit 0

      mkdir -p "$(dirname "$state")"
      if [ "$choice" = "$default" ]; then
        rm -f "$state"
      else
        printf '%s\n' "$choice" > "$state"
      fi
      echo "AI model: $choice"
    '';
  };

  # Usage per model from LiteLLM's spend tracking: `ai-usage [today|7d|30d|YYYY-MM]`
  aiUsage = pkgs.writeShellApplication {
    name = "ai-usage";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
      util-linux
    ];
    text = ''
      token=$(< ${tokenFile})

      report() {
        local title=$1 from=$2 to=$3
        printf '\033[1m%s\033[0m  (%s – %s)\n' "$title" "$from" "$to"
        curl -sf -H "Authorization: Bearer $token" \
          "http://127.0.0.1:${toString ports.gateway}/user/daily/activity/aggregated?start_date=$from&end_date=$to" \
          | jq -r '
              def tok: if . >= 1e6 then "\(. / 1e5 | floor / 10)M"
                elif . >= 1e3 then "\(. / 1e2 | floor / 10)k" else tostring end;
              def usd: "$" + (. * 1e4 | round / 1e4 | tostring);
              [ .results[].breakdown
                | (if (.model_groups | length) > 0 then .model_groups else .models end)
                | to_entries[] ]
              | group_by(.key)
              | map({ model: .[0].key,
                      req: (map(.value.metrics.api_requests) | add),
                      tok: (map(.value.metrics.total_tokens) | add),
                      usd: (map(.value.metrics.spend) | add) })
              | sort_by(-.usd, -.tok)
              | (["MODEL", "REQUESTS", "TOKENS", "COST"] | join("\t")),
                (.[] | [.model, (.req | tostring), (.tok | tok), (.usd | usd)] | join("\t")),
                (["TOTAL", (map(.req) | add // 0 | tostring), (map(.tok) | add // 0 | tok),
                  (map(.usd) | add // 0 | usd)] | join("\t"))
            ' | column -t -s $'\t' -R 2,3,4 \
          || { echo "ai-usage: LiteLLM not reachable or has no database" >&2; exit 1; }
      }

      today=$(date +%F)
      case "''${1:-}" in
        "")
          report "Today" "$today" "$today"
          echo
          report "Last 7 days" "$(date -d '6 days ago' +%F)" "$today"
          echo
          report "This month" "$(date +%Y-%m-01)" "$today"
          ;;
        today) report "Today" "$today" "$today" ;;
        *d) report "Last ''${1%d} days" "$(date -d "$(( ''${1%d} - 1 )) days ago" +%F)" "$today" ;;
        ????-??)
          report "$1" "$1-01" "$(date -d "$1-01 +1 month -1 day" +%F)"
          ;;
        *)
          echo "usage: ai-usage [today|7d|30d|YYYY-MM]" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  inherit
    aiModels
    aiRefresh
    aiModel
    aiUsage
    ;
}
