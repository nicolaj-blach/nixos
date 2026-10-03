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
      # atuin-ai-server config plus cached OpenRouter/Ollama model lists (read by ai-model)
      stateDir = "/var/lib/atuin-ai-server";

      # Refreshes the cached model lists and writes atuin-ai-server's config
      atuinModels = pkgs.writeShellApplication {
        name = "atuin-ai-models";
        runtimeInputs = with pkgs; [
          curl
          jq
          coreutils
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

          # Local first (declared models may still be downloading), then tool-capable OpenRouter models
          jq -n --argjson declared ${lib.escapeShellArg (builtins.toJSON cfg.models)} \
            --slurpfile ol ollama.json --slurpfile or openrouter.json '
              def local($m): { alias: ("ollama/" + $m), name: $m, description: "Local (Ollama)", model: ("ollama/" + $m) };
              ([ $declared[], ($ol[0].models // [] | .[].name) ] | unique | map(local(.)))
              + [ $or[0].data // [] | .[] | select(.supported_parameters | index("tools"))
                  | { alias: ("openrouter/" + .id), name, description: "OpenRouter", model: ("openrouter/" + .id) } ]
            ' > models.json

          default=$(jq -r --arg d ${lib.escapeShellArg cfg.defaultModel} \
            'if any(.[]; .alias == $d) then $d else .[0].alias end' models.json)

          {
            echo 'port = ${toString ports.atuin}'
            echo 'endpoint = "http://127.0.0.1:${toString ports.gateway}/v1"'
            echo 'api_key = { env = "AUTH_TOKEN" }'
            jq -rn --arg d "$default" '"default_model = \($d | tojson)"'
            printf '\n[request.body]\nstream_options = { include_usage = true }\n'
            jq -r '.[] | "\n[[models]]", (to_entries[] | "\(.key) = \(.value | tojson)")' models.json
          } > config.toml.new
          mv config.toml.new config.toml
          chmod 0644 config.toml
          echo "atuin-ai-server: $(jq length models.json) models, default $default"
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
          if systemctl restart podman-atuin-ai-server.service; then
            n=$(grep -c '^\[\[models\]\]' ${stateDir}/config.toml || true)
            notify-send -a "AI" "AI models refreshed" "$n models available"
          else
            notify-send -u critical -a "AI" "AI refresh failed" "journalctl -u podman-atuin-ai-server"
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
          environmentVariables = lib.mkIf (cfg.gpu == "vulkan") { OLLAMA_VULKAN = "1"; };
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
          volumes = [ "${stateDir}/config.toml:/etc/atuin-ai/config.toml:ro" ];
          extraOptions = [ "--network=host" ];
        };

        systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];

        systemd.services.podman-atuin-ai-server = rec {
          after = [
            "litellm.service"
            "ollama.service"
          ];
          wants = after;
          serviceConfig.ExecStartPre = lib.mkBefore [ (lib.getExe atuinModels) ];
        };

        # Let the user refresh the model list without a password
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "podman-atuin-ai-server.service" &&
                action.lookup("verb") == "restart" &&
                subject.user == "${metaOwner.username}") {
              return polkit.Result.YES;
            }
          });
        '';

        environment.systemPackages = [
          aiRefresh
          aiModel
        ];
      };
    };
}
