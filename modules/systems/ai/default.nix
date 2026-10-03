{ inputs, metaOwner, ... }:

{
  # Local AI gateway:
  #   ollama (local models, GPU) + OpenRouter -> LiteLLM (127.0.0.1:4000)
  #   atuin-ai-server (127.0.0.1:8080) -> LiteLLM
  flake.nixosModules.ai =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ai;
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      ports = {
        ollama = 11434;
        gateway = 4000;
        atuin = 8080; # also in apps/shell/zsh.nix (ai.endpoint)
      };

      envFile = config.sops.templates."ai-gateway.env".path;
      tokenFile = config.sops.secrets.ai-gateway-token.path;
      localContext = 16384;

      # Generated model configs for atuin-ai-server, opencode and pi, plus cached model lists
      stateDir = "/var/lib/ai-gateway";

      # One entry per tool-capable model: local Ollama models first, then OpenRouter
      modelList = pkgs.writeText "ai-models.jq" ''
        def per1m: if . == null then 0 else tonumber * 1000000 end;
        def local($m): { alias: ("ollama/" + $m), name: $m, description: "Local (Ollama)", local: true,
          context: ${toString localContext}, output: 8192, input: ["text"],
          cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } };
        # Pulled models without tool calling stay usable with `ollama run` but aren't listed
        ([ $declared[], ($ol[0].models // [] | .[] | select(.capabilities | index("tools")) | .name) ]
          | unique | map(local(.)))
        + [ $or[0].data // [] | .[] | select(.supported_parameters | index("tools"))
            | { alias: ("openrouter/" + .id), name, description: "OpenRouter", local: false,
                context: (.context_length // 128000),
                output: (.top_provider.max_completion_tokens // 16384),
                input: [ .architecture.input_modalities // [] | .[] | select(. == "text" or . == "image") ],
                reasoning: (.supported_parameters | index("reasoning") != null),
                cost: { input: (.pricing.prompt | per1m), output: (.pricing.completion | per1m),
                        cacheRead: (.pricing.input_cache_read | per1m),
                        cacheWrite: (.pricing.input_cache_write | per1m) } } ]
      '';

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
            --from-file ${modelList} > models.json

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

      # One row per model, current first: alias <TAB> visible columns <TAB> preview text
      modelRows = pkgs.writeText "ai-model-rows.jq" ''
        def per1m: if . == null then null else tonumber * 1000000 end;
        def usd: if . == null then "-" elif . == 0 then "free" elif . < 0.01 then "<$0.01"
          else (. * 100 | round | tostring | (if length < 3 then ("00" + .)[-3:] else . end))
            | "$" + .[:-2] + "." + .[-2:] end;
        def ctx: if . == null then "" elif . >= 1000000 then "\(. / 100000 | round / 10)M ctx"
          elif . >= 1000 then "\(. / 1000 | round)K ctx" else "\(.) ctx" end;
        def gb: "\(. / 1e8 | round / 10) GB";
        def pad($n): tostring | .[0:$n] | . + " " * ($n - length);

        ($or[0].data // [] | map({ key: ("openrouter/" + .id), value: . }) | from_entries) as $routes
        | ($ol[0].models // [] | map({ key: ("ollama/" + .name), value: . }) | from_entries) as $locals
        | $srv[0].models
        | (map(select(.alias == $cur)) + map(select(.alias != $cur)))[]
        | .alias as $a
        | ($routes[$a]) as $r
        | ($locals[$a]) as $l
        | (if $a == $cur then "* " else "  " end) + (.name | pad(40)) + "  " as $lead
        | if ($a | startswith("ollama/")) then
            [ $a,
              $lead + ("local" | pad(18)) + "  "
                + ("\($l.details.parameter_size // "?") \($l.details.quantization_level // "")" | pad(14))
                + ($l.size | if . then gb else "" end),
              ([ .name, $a, "",
                 "Runs locally with Ollama (free)",
                 "Parameters:   \($l.details.parameter_size // "?")",
                 "Quantization: \($l.details.quantization_level // "?")",
                 "Family:       \($l.details.family // "?")",
                 "Size on disk: \($l.size | if . then gb else "?" end)"
               ] | join("\\n"))
            ]
          else
            ($r.pricing.prompt | per1m) as $in
            | ($r.pricing.completion | per1m) as $out
            | [ $a,
                $lead + ("\($in | usd) / \($out | usd)" | pad(18)) + "  " + ($r.context_length | ctx),
                ([ .name, $a, "",
                   "Price per 1M tokens",
                   "  input:       \($in | usd)",
                   "  output:      \($out | usd)",
                   "  cache read:  \($r.pricing.input_cache_read | per1m | usd)",
                   "  cache write: \($r.pricing.input_cache_write | per1m | usd)",
                   "  web search:  \($r.pricing.web_search | if . == null then "-" else "$\(.) / search" end)",
                   "",
                   "Context:     \($r.context_length | ctx)",
                   "Max output:  \($r.top_provider.max_completion_tokens // "?") tokens",
                   "Inputs:      \($r.architecture.input_modalities // [] | join(", "))",
                   "",
                   ($r.description // "" | gsub("[\\t\\n]+"; " "))
                 ] | join("\\n"))
              ]
          end
        | @tsv
      '';

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
              --from-file ${modelRows} \
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
    in
    {
      options.ai = {
        enable = lib.mkEnableOption "local AI gateway (ollama, LiteLLM, atuin-ai-server)";

        gpu = lib.mkOption {
          type = lib.types.enum [
            "vulkan"
            "cuda"
            "rocm"
            "cpu"
          ];
          default =
            let
              usesNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
              usesAmdgpu =
                lib.elem "amdgpu" config.services.xserver.videoDrivers
                || config.hardware.amdgpu.initrd.enable
                || lib.elem "amdgpu" config.boot.initrd.kernelModules
                || lib.any (lib.hasPrefix "amdgpu.") config.boot.kernelParams;
            in
            if usesNvidia || usesAmdgpu then "vulkan" else "cpu";
          description = ''
            Ollama GPU backend. vulkan works on any NVIDIA or AMD GPU (default when one is found).
            cuda is faster on NVIDIA Turing (RTX 20xx) and newer; the cached build skips older
            cards like the GTX 1080. rocm targets supported AMD GPUs.
          '';
        };

        rocmOverrideGfx = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "10.3.0";
          description = "HSA_OVERRIDE_GFX_VERSION for AMD GPUs ROCm doesn't detect.";
        };

        models = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "qwen2.5:7b"
            "llama3.2:3b"
          ];
          description = "Ollama models pulled on activation.";
        };

        defaultModel = lib.mkOption {
          type = lib.types.str;
          # llama3.2:3b emits malformed tool calls with atuin; qwen2.5:7b handles them
          default = "ollama/qwen2.5:7b";
        };
      };

      config = lib.mkIf cfg.enable {
        # Prebuilt CUDA packages (ollama-cuda is unfree, so not on cache.nixos.org)
        nix.settings = lib.mkIf (cfg.gpu == "cuda") {
          substituters = [ "https://cache.nixos-cuda.org" ];
          trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
        };

        services.ollama = {
          enable = true;
          package =
            {
              cuda = unstable.ollama-cuda;
              rocm = unstable.ollama-rocm;
              vulkan = unstable.ollama-vulkan;
              cpu = unstable.ollama;
            }
            .${cfg.gpu};
          host = "127.0.0.1";
          port = ports.ollama;
          loadModels = cfg.models;
          rocmOverrideGfx = lib.mkIf (cfg.gpu == "rocm") cfg.rocmOverrideGfx;
          # Coding agents send 8-20k tokens per request; 16k keeps qwen2.5:7b on the 8 GB GPU
          environmentVariables = {
            OLLAMA_CONTEXT_LENGTH = toString localContext;
          }
          // lib.optionalAttrs (cfg.gpu == "vulkan") { OLLAMA_VULKAN = "1"; };
        };

        services.litellm = {
          enable = true;
          host = "127.0.0.1";
          port = ports.gateway;
          environmentFile = envFile;
          settings = {
            model_list = [
              {
                model_name = "openrouter/*";
                litellm_params = {
                  model = "openrouter/*";
                  api_key = "os.environ/OPENROUTER_API_KEY";
                };
              }
              {
                model_name = "ollama/*";
                litellm_params = {
                  # Ollama's OpenAI-compatible API accepts content-part arrays (ollama_chat doesn't)
                  model = "openai/*";
                  api_base = "http://127.0.0.1:${toString ports.ollama}/v1";
                  api_key = "ollama";
                };
              }
            ];
            general_settings.master_key = "os.environ/AUTH_TOKEN";
            litellm_settings.drop_params = true;
          };
        };

        virtualisation.podman.enable = true;

        virtualisation.oci-containers.containers.atuin-ai-server = {
          image = "ghcr.io/atuinsh/atuin-ai-server@sha256:3d11028588ebfddb0685169e35cbc7121d3577b6eee3831e845fbe5c28e48d92";
          environmentFiles = [ envFile ];
          volumes = [ "${stateDir}/atuin.toml:/etc/atuin-ai/config.toml:ro" ];
          extraOptions = [ "--network=host" ];
        };

        systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];

        # Model configs for atuin-ai-server, opencode and pi: at boot, hourly, and by ai-refresh
        systemd.services.ai-models = {
          description = "Generate AI gateway model configs";
          after = [
            "ollama.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe aiModels;
          };
        };

        systemd.timers.ai-models = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "hourly";
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.podman-atuin-ai-server = rec {
          after = [
            "ai-models.service"
            "litellm.service"
            "ollama.service"
          ];
          wants = after;
        };

        # Let the user refresh the model lists without a password
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                ["ai-models.service", "podman-atuin-ai-server.service"].indexOf(action.lookup("unit")) >= 0 &&
                action.lookup("verb") == "restart" &&
                subject.user == "${metaOwner.username}") {
              return polkit.Result.YES;
            }
          });
        '';

        # opencode and pi get a "litellm" provider next to their own ones
        home-manager.sharedModules = [
          (
            { config, ... }:
            {
              home.sessionVariables.OPENCODE_CONFIG = "${stateDir}/opencode.json";
              home.file.".pi/agent/models.json".source =
                config.lib.file.mkOutOfStoreSymlink "${stateDir}/pi-models.json";
            }
          )
        ];

        environment.systemPackages = [
          aiRefresh
          aiModel
        ];
      };
    };
}
